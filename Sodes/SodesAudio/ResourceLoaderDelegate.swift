//
//  ResourceLoaderDelegate.swift
//  SodesAudio
//
//  Created by Jared Sinclair on 7/14/16.
//
//

import Foundation
import AVFoundation
import CommonCryptoSwift
import SodesFoundation
import SwiftableFileHandle

protocol ResourceLoaderDelegateDelegate: class {
    func resourceLoaderDelegate(_ delegate: ResourceLoaderDelegate, didEncounter error: Error?)
    func resourceLoaderDelegate(_ delegate: ResourceLoaderDelegate, didUpdateLoadedByteRanges ranges: [ByteRange])
}

///-----------------------------------------------------------------------------
/// ResourceLoaderDelegate
///-----------------------------------------------------------------------------

/// Custom AVAssetResourceLoaderDelegate which stores downloaded audio data to
/// re-usable scratch files on disk. This class thus allows an audio file to be
/// streamed across multiple app sessions with the least possible amount of
/// redownloaded data.
/// 
/// ResourceLoaderDelegate does not currently keep data for more than one 
/// resource at a time. If the user frequently changes audio sources this class
/// will be of limited benefit. In the future, it might be wise to provide a
/// dynamic maximum number of cached sources, perhaps keeping data for the most
/// recent 3 to 5 sources.
internal class ResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {

    /// Enough said.
    internal enum ErrorStatus {
        case none
        case error(Error?)
    }
    
    // MARK: Internal Properties
    
    /// The ResourceLoaderDelegate's, err..., delegate.
    internal weak var delegate: ResourceLoaderDelegateDelegate?
    
    /// Provides initial chunks of data to speed up time-to-play when streaming.
    internal weak var initialChunkCache: InitialChunkCache?
    
    /// Provides cache validation info to spare an initial roundtrip HEAD request.
    internal weak var metaDataCache: MetadataCache?
    
    /// The current error status
    internal fileprivate(set) var errorStatus: ErrorStatus = .none
    
    // MARK: Private Properties (Immutable)
    
    /// Used to store the URL for the most-recently used audio source.
    fileprivate let defaults: UserDefaults
    
    /// The directory where all scratch file subdirectories are stored.
    fileprivate let resourcesDirectory: URL
    
    /// A loading scheme used to ensure that the AVAssetResourceLoader routes
    /// its requests to this class.
    fileprivate let customLoadingScheme: String
    
    /// A serial queue on which AVAssetResourceLoader will call delegate methods.
    fileprivate let loaderQueue: DispatchQueue
    
    /// A date formatter used when parsing Last-Modified header values.
    fileprivate let formatter = RFC822Formatter()
    
    /// A throttle used to limit how often we save scratch file metadata (byte
    /// ranges, cache validation header info) to disk.
    fileprivate let byteRangeThrottle = Throttle(
        minimumInterval: 1.0,
        qualityOfService: .background
    )
    
    // MARK: Private Properties (Mutable)
    
    /// The current resource loader. We can't assume that the same one will
    /// always be used, so keeping a reference to it here helps us avoid
    /// cross-talk between audio sessions.
    fileprivate var currentAVAssetResourceLoader: AVAssetResourceLoader?
    
    /// The info for the scratch file for the current session.
    fileprivate var scratchFileInfo: ScratchFileInfo? {
        didSet {
            if let oldValue = oldValue {
                if oldValue.resourceUrl != scratchFileInfo?.resourceUrl {
                    unprepare(oldValue)
                }
            }
        }
    }
    
    /// The request wrapper object containg references to all the info needed
    /// to process the current AVAssetResourceLoadingRequest.
    fileprivate var currentRequest: Request? {
        didSet {
            // Under conditions that I don't know how to reproduce, AVFoundation
            // sometimes fails to cancel previous requests that cover ~90% of 
            // of the previous. It seems to happen when repeatedly seeking, but
            // it could have been programmer error. Either way, in my testing, I 
            // found that cancelling (by finishing early w/out data) the 
            // previous request, I can keep the activity limited to a single 
            // request and vastly improve loading times, especially on poor 
            // networks.
            oldValue?.cancel()
        }
    }
    
    // MARK: Init/Deinit
    
    /// Designated initializer.
    internal init(customLoadingScheme: String, resourcesDirectory: URL, defaults: UserDefaults) {
        
        SodesLog(resourcesDirectory)
        
        self.defaults = defaults
        self.resourcesDirectory = resourcesDirectory
        self.customLoadingScheme = customLoadingScheme
        self.loaderQueue = DispatchQueue(label: "com.SodesAudio.ResourceLoaderDelegate.loaderQueue")
        
        super.init()
        
        // Remove zombie scratch file directories in case of a premature exit
        // during a previous session.
        if let mostRecentResourceUrl = defaults.mostRecentResourceUrl {
            let directoryToKeep = scratchFileDirectory(for: mostRecentResourceUrl).lastPathComponent
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: resourcesDirectory.path) {
                for directoryName in contents.filter({$0 != directoryToKeep && !$0.hasPrefix(".")}) {
                    SodesLog("Removing zombie scratch directory at: \(directoryName)")
                    let url = resourcesDirectory.appendingPathComponent(directoryName, isDirectory: true)
                    _ = FileManager.default.removeDirectory(url)
                }
            }
        }
    }
    
    // MARK: Internal Methods
    
    /// Prepares an AVURLAsset, configuring the resource loader's delegate, etc.
    /// This method returns nil if the receiver cannot prepare an asset that it
    /// can handle.
    internal func prepareAsset(for url: URL) -> AVURLAsset? {
        
        errorStatus = .none
        
        guard url.hasPathExtension("mp3") else {
            SodesLog("Bad url: \(url)\nResourceLoaderDelegate only supports urls with an .mp3 path extension.")
            return nil
        }

        guard let redirectUrl = url.convertToRedirectURL(prefix: customLoadingScheme) else {
            SodesLog("Bad url: \(url)\nCould not convert the url to a redirect url.")
            return nil
        }
        
        currentAVAssetResourceLoader = nil
        
        // If there's no scratch file info, that means that playback has not yet
        // begun during this app session. A previous session could still have 
        // its scratchfile data on disk. If the most recent resource url is the
        // same as `url`, then leave it as-is so we can re-use the data. 
        // Otherwise, remove that data from disk.
        
        if scratchFileInfo == nil {
            if let previous = defaults.mostRecentResourceUrl, previous != url {
                removeFiles(for: previous)
            }
        }
        
        loaderQueue.sync {
            currentRequest = nil
            scratchFileInfo = prepareScratchFileInfo(for: url)
        }
        
        guard scratchFileInfo != nil else {
            assertionFailure("Could not create scratch file info for: \(url)")
            defaults.mostRecentResourceUrl = nil
            return nil
        }
        
        delegate?.resourceLoaderDelegate(self, didUpdateLoadedByteRanges: scratchFileInfo!.loadedByteRanges)
        
        defaults.mostRecentResourceUrl = url
        
        let asset = AVURLAsset(url: redirectUrl)
        asset.resourceLoader.setDelegate(self, queue: loaderQueue)
        currentAVAssetResourceLoader = asset.resourceLoader
        
        return asset
    }
    
    // MARK: Private Methods
    
    /// Convenience method for handling a content info request.
    fileprivate func handleContentInfoRequest(for loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        SodesLog("Will attempt to handle content info request.")
        
        guard let infoRequest = loadingRequest.contentInformationRequest else {return false}
        guard let redirectURL = loadingRequest.request.url else {return false}
        guard let originalURL = redirectURL.convertFromRedirectURL(prefix: customLoadingScheme) else {return false}
        guard let scratchFileInfo = self.scratchFileInfo else {return false}
        
        SodesLog("Will handle content info request.")
        
        // This may be naive, but in practice it should work well often enough
        // that the naivete poses a minimal risk. If our scratch file's 
        // expected content length is the same as the expected length from the
        // playback source provider's metadata, then well assume that our 
        // scratch file is the same as the originally-posted item. This will
        // pose a much larger risk if we ever start caching more than the 
        // current episode. Since we're only caching the current episode, we can
        // expect that the data will be more short-lived and thus exposed to
        // a smaller risk of becoming invalid. If we're misjudging the risk, we
        // could also toss the scratch file if it hasn't been touched in more
        // than N hours.
        
        let disposition = ContentInfoRequestDisposition.disposition(
            using: metaDataCache,
            url: originalURL,
            currentCacheInfo: scratchFileInfo.cacheInfo
        )
        
        if case .useSimulatedResponse(let length) = disposition {
            SodesLog("Using cached value for expected content length: \(length)")
            infoRequest.contentLength = length
            infoRequest.isByteRangeAccessSupported = true
            infoRequest.contentType = "public/mp3"
            loadingRequest.finishLoading()
            return true
        }
        
        SodesLog("Unable to use cached value for expected content length. Will make a content info request.")
        
        // Even though we re-use the downloaded bytes from a previous session,
        // we should always make a roundtrip for the content info requests so
        // that we can use HTTP cache validation header values to see if we need
        // to redownload the data. Podcast MP3s can be replaced without changing
        // the URL for the episode (adding new commercials to old episodes, etc.)
        
        let request: URLRequest = {
            var request = URLRequest(url: originalURL)
            if let dataRequest = loadingRequest.dataRequest {
                // Nota Bene: Even though the content info request is often
                // accompanied by a data request, **do not** invoke the data
                // requests `respondWithData()` method as this will put the 
                // asset loading request into an undefined state. This isn't
                // documented anywhere, but beware.
                request.setByteRangeHeader(for: dataRequest.byteRange)
            }
            return request
        }()
        
        let task = URLSession.shared.downloadTask(with: request) { (tempUrl, response, error) in
            
            // I'm using strong references to `self` because I don't know if
            // AVFoundation could recover if `self` became nil before cancelling
            // all active requests. Retaining `self` here is easier than the
            // alternatives. Besides, this class has been designed to accompany
            // a singleton PlaybackController.
            
            self.loaderQueue.async {
                
                // Bail early if the content info request was cancelled.
                
                guard !loadingRequest.isCancelled else
                {
                    SodesLog("Bailing early because the loading request was cancelled.")
                    return
                }
                
                guard let request = self.currentRequest as? ContentInfoRequest,
                    loadingRequest === request.loadingRequest else
                {
                    SodesLog("Bailing early because the loading request has changed.")
                    return
                }
                
                guard let delayedScratchFileInfo = self.scratchFileInfo,
                    delayedScratchFileInfo === scratchFileInfo else
                {
                    SodesLog("Bailing early because the scratch file info has changed.")
                    return
                }
                
                if let response = response, error == nil {
                    
                    // Check the Etag and Last-Modified header values to see if
                    // the file has changed since the last cache info was
                    // fetched (if this is the first time we're seeing this 
                    // file, the existing info will be blank, which is fine). If
                    // the cached info is no longer valid, wipe the loaded byte
                    // ranges from the metadata and update the metadata with the
                    // new Etag/Last-Modified header values.
                    // 
                    // If the content provider never provides cache validation
                    // values, this means we will always re-download the data.
                    // 
                    // Note that we're not removing the bytes from the actual
                    // scratch file on disk. This may turn out to be a bad idea,
                    // but for now lets assume that our byte range metadata is
                    // always up-to-date, and that by resetting the loaded byte
                    // ranges here we will prevent future subrequests from 
                    // reading byte ranges that have since been invalidated.
                    // This works because DataRequestLoader will not create any
                    // scratch file subrequests if the loaded byte ranges are
                    // empty.
                    
                    let cacheInfo = response.cacheInfo(using: self.formatter)
                    if !delayedScratchFileInfo.cacheInfo.isStillValid(comparedTo: cacheInfo) {
                        delayedScratchFileInfo.cacheInfo = cacheInfo
                        self.saveUpdatedScratchFileMetaData(immediately: true)
                        SodesLog("Reset the scratch file meta data since the cache validation values have changed.")
                    }
                    
                    SodesLog("Item completed: content request: \(response)")
                    
                    infoRequest.update(with: response)
                    loadingRequest.finishLoading()
                }
                else {
                    
                    // Do not update the scratch file meta data here since the
                    // request could have failed for any number of reasons.
                    // Let's only reset meta data if we receive a successful
                    // response.
                    
                    SodesLog("Failed with error: \(error)")
                    self.finish(loadingRequest, with: error)
                }
                
                if self.currentRequest === request {
                    // Nil-out `currentRequest` since we're done with it, but
                    // only if the value of self.currentRequest didn't change
                    // (since we just called `loadingRequest.finishLoading()`.
                    self.currentRequest = nil
                }
            }
        }
        
        self.currentRequest = ContentInfoRequest(
            resourceUrl: originalURL,
            loadingRequest: loadingRequest,
            infoRequest: infoRequest,
            task: task
        )
        
        task.resume()
        
        return true

    }
    
    /// Convenience method for handling a data request. Uses a DataRequestLoader
    /// to load data from either the scratch file or the network, optimizing for
    /// the former to prevent unnecessary network usage.
    fileprivate func handleDataRequest(for loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        
        SodesLog("Will attempt to handle data request.")
        
        guard let avDataRequest = loadingRequest.dataRequest else {return false}
        guard let redirectURL = loadingRequest.request.url else {return false}
        guard let originalURL = redirectURL.convertFromRedirectURL(prefix: customLoadingScheme) else {return false}
        guard let scratchFileInfo = scratchFileInfo else {return false}
        
        SodesLog("Can handle this data request.")
        
        let lowerBound = avDataRequest.requestedOffset
        let length = avDataRequest.requestedLength
        let upperBound = lowerBound + length
        let dataRequest: DataRequest = {
            let loader = DataRequestLoader(
                resourceUrl: originalURL,
                requestedRange: (lowerBound..<upperBound),
                delegate: self,
                callbackQueue: loaderQueue,
                scratchFileHandle: scratchFileInfo.fileHandle,
                scratchFileRanges: scratchFileInfo.loadedByteRanges,
                initialChunkCache: initialChunkCache
            )
            return DataRequest(
                resourceUrl: originalURL,
                loadingRequest: loadingRequest,
                dataRequest: avDataRequest,
                loader: loader
            )
        }()
        self.currentRequest = dataRequest
        dataRequest.loader.start()
        
        return true
    }
    
}

///-----------------------------------------------------------------------------
/// ResourceLoaderDelegate: AVAssetResourceLoaderDelegate
///-----------------------------------------------------------------------------

extension ResourceLoaderDelegate {
    
    /// Initiates a new loading request. This could be either a content info or
    /// a data request. This method returns `false` if the request cannot be
    /// handled.
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard currentAVAssetResourceLoader === resourceLoader else {return false}
        if let _ = loadingRequest.contentInformationRequest {
            return handleContentInfoRequest(for: loadingRequest)
        } else if let _ = loadingRequest.dataRequest {
            return handleDataRequest(for: loadingRequest)
        } else {
            return false
        }
    }
    
    /// Not used. Throws a fatal error when hit. ResourceLoaderDelegate has not
    /// been designed to be used with assets that require authentication.
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        fatalError()
    }
    
    /// Cancels the current request.
    @objc(resourceLoader:didCancelLoadingRequest:) func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        guard let request = currentRequest as? DataRequest else {return}
        guard loadingRequest === request.loadingRequest else {return}
        currentRequest = nil
    }
    
}

///-----------------------------------------------------------------------------
/// ResourceLoaderDelegate: Scratch File Info Handling
///-----------------------------------------------------------------------------

fileprivate extension ResourceLoaderDelegate {
    
    /// Returns a unique id for `url`.
    func identifier(for url: URL) -> String {
        return Hash.MD5(url.absoluteString)!
    }
    
    /// Returns the desired URL for the scratch file subdirectory for `resourceUrl`.
    func scratchFileDirectory(for resourceUrl: URL) -> URL {
        let directoryName = identifier(for: resourceUrl)
        return resourcesDirectory.appendingPathComponent(directoryName, isDirectory: true)
    }
    
    /// Prepares a subdirectory for the scratch file and its metadata, as well
    /// as a file handle for reading/writing. This method returns nil if there
    /// was an unrecoverable error during setup.
    func prepareScratchFileInfo(for resourceUrl: URL) -> ScratchFileInfo? {
        
        let directory = scratchFileDirectory(for: resourceUrl)
        let scratchFileUrl = directory.appendingPathComponent("scratch", isDirectory: false)
        let metaDataUrl = directory.appendingPathComponent("metadata.xml", isDirectory: false)
        
        guard FileManager.default.createDirectoryAt(directory) else {return nil}
        
        if !FileManager.default.fileExists(atPath: scratchFileUrl.path) {
            FileManager.default.createFile(atPath: scratchFileUrl.path, contents: nil)
        }
        
        guard let fileHandle = SODSwiftableFileHandle(url: scratchFileUrl) else {return nil}
        
        let (ranges, cacheInfo): ([ByteRange], ScratchFileInfo.CacheInfo)
        if let (r,c) = FileManager.default.readRanges(at: metaDataUrl) {
            (ranges, cacheInfo) = (r, c)
        } else {
            let info = ScratchFileInfo.CacheInfo(
                contentLength: metaDataCache?.expectedLengthInBytes(for: resourceUrl),
                etag: nil,
                lastModified: nil
            )
            (ranges, cacheInfo) = ([], info)
        }
        
        SodesLog("Prepared info using directory:\n\(directory)\ncacheInfo: \(cacheInfo)")
        
        return ScratchFileInfo(
            resourceUrl: resourceUrl,
            directory: directory,
            scratchFileUrl: scratchFileUrl,
            metaDataUrl: metaDataUrl,
            fileHandle: fileHandle,
            cacheInfo: cacheInfo,
            loadedByteRanges: ranges
        )
        
    }
    
    /// Closes the file handle and removes the scratch file subdirectory.
    func unprepare(_ info: ScratchFileInfo) {
        info.fileHandle.closeFile()
        _ = FileManager.default.removeDirectory(info.directory)
    }
    
    /// Removes the scratch file subdirectory for `resourceUrl`, if any.
    func removeFiles(for resourceUrl: URL) {
        let directory = scratchFileDirectory(for: resourceUrl)
        _ = FileManager.default.removeDirectory(directory)
    }
    
    /// Updates the loaded byte ranges for the current scratch file info. This
    /// is done by combining all contiguous/overlapping ranges. This also saves
    /// the result to disk using `throttle`.
    func updateLoadedByteRanges(additionalRange: ByteRange) {
        guard let info = scratchFileInfo else {return}
        info.loadedByteRanges.append(additionalRange)
        info.loadedByteRanges = combine(info.loadedByteRanges)
        saveUpdatedScratchFileMetaData()
    }
    
    /// Convenience method for saving the current scratch file metadata.
    ///
    /// - parameter immediately: Forces the throttle to process the save now.
    /// Passing `false` will use the default throttling mechanism.
    func saveUpdatedScratchFileMetaData(immediately: Bool = false) {
        guard let currentUrl = currentRequest?.resourceUrl else {return}
        guard let info = scratchFileInfo else {return}
        byteRangeThrottle.enqueue(immediately: immediately) { [weak self] in
            guard let this = self else {return}
            guard currentUrl == this.currentRequest?.resourceUrl else {return}
            guard let delayedInfo = this.scratchFileInfo else {return}
            let combinedRanges = combine(info.loadedByteRanges)
            _ = FileManager.default.save(
                byteRanges: combinedRanges,
                cacheInfo: info.cacheInfo,
                to: delayedInfo.metaDataUrl
            )
            this.delegate?.resourceLoaderDelegate(this, didUpdateLoadedByteRanges: combinedRanges)
        }
    }
    
    func finish(_ loadingRequest: AVAssetResourceLoadingRequest, with error: Error?) {
        self.errorStatus = .error(error)
        loadingRequest.finishLoading(with: error as? NSError)
        DispatchQueue.main.async {
            if case .error(_) = self.errorStatus {
                self.delegate?.resourceLoaderDelegate(self, didEncounter: error)
            }
        }
    }
    
}

///-----------------------------------------------------------------------------
/// ResourceLoaderDelegate: DataRequestLoaderDelegate
///-----------------------------------------------------------------------------

extension ResourceLoaderDelegate: DataRequestLoaderDelegate {
    
    /// Updates the loaded byte ranges for the scratch file info, and appends
    /// the data to the current data request. This method will only be called
    /// after `data` has already been successfully written to the scratch file.
    func dataRequestLoader(_ loader: DataRequestLoader, didReceive data: Data, forSubrange subrange: ByteRange) {
        guard let request = currentRequest as? DataRequest else {return}
        guard loader === request.loader else {return}
        updateLoadedByteRanges(additionalRange: subrange)
        request.dataRequest.respond(with: data)
    }
    
    /// Called with the DataRequestLoader has finished all subrequests.
    func dataRequestLoaderDidFinish(_ loader: DataRequestLoader) {
        guard let request = currentRequest as? DataRequest else {return}
        guard loader === request.loader else {return}
        request.loadingRequest.finishLoading()
    }
    
    /// Called when the DataRequestLoader encountered an error. It will not 
    /// proceed with pending subrequests if it encounters an error while 
    /// handling a given subrequest.
    func dataRequestLoader(_ loader: DataRequestLoader, didFailWithError error: Error?) {
        guard let request = currentRequest as? DataRequest else {return}
        guard loader === request.loader else {return}
        finish(request.loadingRequest, with: error)
    }
    
}

///-----------------------------------------------------------------------------
/// UserDefaults: Convenience Methods
///-----------------------------------------------------------------------------

fileprivate let mostRecentResourceUrlKey = "com.sodesaudio.ResourceLoaderDelegate.mostRecentResourceUrl"

fileprivate extension UserDefaults {
    
    /// Stores the URL for the most-recently used audio source.
    var mostRecentResourceUrl: URL? {
        get {
            if let string = self.string(forKey: mostRecentResourceUrlKey) {
                return URL(string: string)
            } else {
                return nil
            }
        }
        set { set(newValue?.absoluteString, forKey: mostRecentResourceUrlKey) }
    }
    
}
