//
//  DataRequestLoader.swift
//  SodesAudio
//
//  Created by Jared Sinclair on 8/7/16.
//
//

import Foundation
import AVFoundation
import SwiftableFileHandle
import SodesFoundation

protocol DataRequestLoaderDelegate: class {
    func dataRequestLoader(_ loader: DataRequestLoader, didReceive data: Data, forSubrange subrange: ByteRange)
    func dataRequestLoaderDidFinish(_ loader: DataRequestLoader)
    func dataRequestLoader(_ loader: DataRequestLoader, didFailWithError error: Error?)
}

/// Loads data for a given AVAssetResourceLoadingRequest. The data is loaded 
/// from either the scratch file on disk or else downloaded from the Internet.
/// If data is downloaded from the internet, the data will first be written to
/// the scratch file, and then (if that write was successful) it will be passed
/// onto the DataRequestLoader's delegate (which will pass that data onto 
/// AVFoundation).
class DataRequestLoader {
    
    // MARK: Internal Properties
    
    /// The remote URL for the audio file.
    let resourceUrl: URL
    
    /// The requested byte range.
    let requestedRange: ByteRange
    
    // MARK: File Private Properties (Immutable)
    
    /// The available ranges in the scratch file which can be read from when
    /// servicing the request.
    fileprivate let scratchFileRanges: [ByteRange]
    
    /// Provides initial chunks of data.
    fileprivate weak var initialChunkCache: InitialChunkCache?
    
    /// The callback queue on which HTTP callbacks are received.
    fileprivate let httpCallbackQueue: OperationQueue
    
    /// The callback queue on which delegate methods will be invoked.
    fileprivate let callbackQueue: DispatchQueue
    
    /// The operation queue on which subrequest operations are enqueued.
    fileprivate let operationQueue: OperationQueue
    
    /// A file handle used for reading/writing data from/to the scratch file.
    fileprivate let scratchFileHandle: SODSwiftableFileHandle
    
    // MARK: File Private Properties (Mutable)
    
    /// The delegate.
    fileprivate weak var delegate: DataRequestLoaderDelegate?
    
    /// The current offset within the scratch file.
    fileprivate var currentOffset: Int64
    
    /// If `true` the request was cancelled.
    fileprivate var cancelled = false
    
    /// If `false` the request has failed.
    fileprivate var failed = false
    
    // MARK: Init
    
    /// Designated initializer.
    init(resourceUrl: URL, requestedRange: ByteRange, delegate: DataRequestLoaderDelegate, callbackQueue: DispatchQueue, scratchFileHandle: SODSwiftableFileHandle, scratchFileRanges: [ByteRange], initialChunkCache: InitialChunkCache?) {
        self.resourceUrl = resourceUrl
        self.requestedRange = requestedRange
        self.initialChunkCache = initialChunkCache
        self.callbackQueue = callbackQueue
        self.httpCallbackQueue = {
           let queue = OperationQueue()
            queue.maxConcurrentOperationCount = 1
            return queue
        }()
        self.delegate = delegate
        self.scratchFileHandle = scratchFileHandle
        self.scratchFileRanges = scratchFileRanges
        self.currentOffset = requestedRange.lowerBound
        self.operationQueue = {
            let queue = OperationQueue()
            queue.maxConcurrentOperationCount = 1
            return queue
        }()
    }
    
    // MARK: Internal Methods
    
    /// Starts loading the data for the request.
    func start() {
        guard !cancelled && !failed else {return}
        let subrequests = ResourceLoaderSubrequest.subrequests(
            requestedRange: requestedRange,
            scratchFileRanges: scratchFileRanges,
            initialChunkCacheRange: initialChunkCache?.initialChunkRange(for: resourceUrl)
        )
        SodesLog("Starting for requestedRange: \(requestedRange), scratchFileRanges: \(scratchFileRanges). Will enqueue operations for subrequests: \(subrequests)")
        operationQueue.addOperations(newOperations(for: subrequests), waitUntilFinished: false)
    }
    
    /// Cancels loading.
    func cancel() {
        cancelled = true
        operationQueue.cancelAllOperations()
    }
    
    // MARK: fileprivate Methods
    
    /// Creates an array of Operations that will fulfill `subrequests`.
    fileprivate func newOperations(for subrequests: [ResourceLoaderSubrequest]) -> [Operation] {
        return subrequests.map { (subrequest) -> Operation in
            switch subrequest.source {
            case .initialChunkCache:
                return newInitialChunkCacheOperation(for: subrequest.range)
            case .scratchFile:
                return newScratchFileOperation(for: subrequest.range)
            case .network:
                return newNetworkRequestOperation(for: resourceUrl, range: subrequest.range)
            }
        }
    }
    
    /// Creates an operation which will load `range` from the initial chunk cache.
    fileprivate func newInitialChunkCacheOperation(for range: ByteRange) -> Operation {
        return BlockOperation { [weak self] in
            guard let this = self else {return}
            guard !this.cancelled && !this.failed else {return}
            SodesLog("Will read data from inital chunk cache for range: \(range)")
            let chunk = this.initialChunkCache?.initialChunk(for: this.resourceUrl)
            if let subdata = chunk?.byteRangeResponseSubdata(in: range) {
                this.currentOffset = range.upperBound
                this.callbackQueue.sync { [weak this] in
                    guard let this = this else {return}
                    guard !this.cancelled && !this.failed else {return}
                    this.delegate?.dataRequestLoader(this, didReceive: subdata, forSubrange: range)
                }
            } else {
                let fallbackOp: Operation = {
                    let op = this.newNetworkRequestOperation(for: this.resourceUrl, range: range)
                    op.queuePriority = .veryHigh
                    return op
                }()
                this.operationQueue.addOperation(fallbackOp)
            }
        }
    }
    
    /// Creates an operation which will load `range` from the scratch file.
    fileprivate func newScratchFileOperation(for range: ByteRange) -> Operation {
        SodesLog("Creating operation for scratch file for range: \(range)")
        return BlockOperation { [weak self] in
            guard let this = self else {return}
            guard !this.cancelled && !this.failed else {return}
            do {
                let data = try this.scratchFileHandle.read(from: range)
                this.currentOffset = range.upperBound
                this.callbackQueue.sync { [weak this] in
                    guard let this = this else {return}
                    guard !this.cancelled && !this.failed else {return}
                    SodesLog("Sucessfully read data from the scratch file: \(range)")
                    this.delegate?.dataRequestLoader(this, didReceive: data, forSubrange: range)
                }
            } catch (let e) {
                SodesLog(e)
                this.fail(with: e)
            }
        }
    }
    
    /// Creates an operation which will download `range` from `url`.
    fileprivate func newNetworkRequestOperation(for url: URL, range: ByteRange) -> Operation {
        SodesLog("Creating operation for byte range: \(range).")
        return DelegatedHTTPOperation(
            request: URLRequest.dataRequest(from: url, for: range),
            configuration: .default,
            dataDelegate: self,
            delegateQueue: httpCallbackQueue,
            completion: { [weak self] (result) in
                guard let this = self else {return}
                guard !this.cancelled && !this.failed else {return}
                switch result {
                case .success(_, let bytesExpected, let bytesReceived):
                    SodesLog("bytesExpected: \(bytesExpected), bytesReceived: \(bytesReceived)")
                    // No-op, just let the procedure continue onto the next operation
                    break
                case .error(let response,let error):
                    SodesLog("\(error): \(response)")
                    this.fail(with: error)
                }
        })
    }
    
    /// Safely moves the request loader into its failed state.
    fileprivate func fail(with error: Error?) {
        failed = true
        operationQueue.cancelAllOperations()
        operationQueue.addOperation { [weak self] in
            guard let this = self else {return}
            guard !this.cancelled else {return}
            this.callbackQueue.async {
                this.delegate?.dataRequestLoader(this, didFailWithError: error)
            }
        }
    }
    
}

extension DataRequestLoader: HTTPOperationDataDelegate {
    
    /// Will be called when the operation receives a success-level response.
    /// This gives the receiver a chance to respond to it in case there's a
    /// domain-specific error.
    func delegatedHTTPOperation(_ operation: DelegatedHTTPOperation, didReceiveResponse response: HTTPURLResponse) {
        
        assert(OperationQueue.current === httpCallbackQueue)
        
        // As of this writing, DelegatedHTTPOperation should treat status codes
        // outside this 200-level range as errors, not calling this delegate
        // method but finishing with an error.
        assert(200 <= response.statusCode && response.statusCode <= 299)
        
        if !response.sodes_isByteRangeEnabledResponse {
            assertionFailure("Byte ranges not supported by this server. What gives?")
            fail(with: SodesAudioError.byteRangeAccessNotSupported(response))
        }
        
    }
    
    /// This will be called many times a second as chunks of data are loaded.
    /// The receiver will write the data to the scratch file and, if successful,
    /// will notify its delegate of the loaded data. The receiver will pass the
    /// data onto AVFoundation and update the metadata registry of loaded 
    /// byte ranges.
    func delegatedHTTPOperation(_ operation: DelegatedHTTPOperation, didReceiveData data: Data) {
        
        assert(OperationQueue.current === httpCallbackQueue)
                
        do {
            try scratchFileHandle.write(data, at: UInt64(currentOffset))
            scratchFileHandle.synchronizeFile()
            let range: ByteRange = (currentOffset..<currentOffset+data.count)
            currentOffset = range.upperBound
            callbackQueue.sync { [weak self] in
                guard let this = self else {return}
                guard !this.cancelled && !this.failed else {return}
                this.delegate?.dataRequestLoader(this, didReceive: data, forSubrange: range)
            }
        }
        catch {
            fail(with: error)
        }
    }
    
}
