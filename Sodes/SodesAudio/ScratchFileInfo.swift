//
//  ScratchFileInfo.swift
//  SodesAudio
//
//  Created by Jared Sinclair on 8/16/16.
//
//

import Foundation
import SwiftableFileHandle
import SodesFoundation

/// Info for the current scratch file for ResourceLoaderDelegate.
class ScratchFileInfo {
    
    /// Cache validation info.
    struct CacheInfo {
        let contentLength: Int64?
        let etag: String?
        let lastModified: Date?
    }
    
    /// The remote URL from which the file should be downloaded.
    let resourceUrl: URL
    
    /// The subdirectory for this scratch file and its metadata.
    let directory: URL
    
    /// The file url to the scratch file itself.
    let scratchFileUrl: URL
    
    /// The file url to the metadata for the scratch file.
    let metaDataUrl: URL
    
    /// The file handle used for reading/writing bytes to the scratch file.
    let fileHandle: SODSwiftableFileHandle
    
    /// The most recent cache validation info.
    var cacheInfo: CacheInfo
    
    /// The byte ranges for the scratch file that have been saved thus far.
    var loadedByteRanges: [ByteRange]
    
    /// Designated initializer.
    init(resourceUrl: URL, directory: URL, scratchFileUrl: URL, metaDataUrl: URL, fileHandle: SODSwiftableFileHandle, cacheInfo: CacheInfo, loadedByteRanges: [ByteRange]) {
        self.resourceUrl = resourceUrl
        self.directory = directory
        self.scratchFileUrl = scratchFileUrl
        self.metaDataUrl = metaDataUrl
        self.fileHandle = fileHandle
        self.cacheInfo = cacheInfo
        self.loadedByteRanges = loadedByteRanges
    }
    
}

extension ScratchFileInfo.CacheInfo {
    
    static let none = ScratchFileInfo.CacheInfo(
        contentLength: nil, etag: nil, lastModified: nil
    )
    
    func isStillValid(comparedTo otherInfo: ScratchFileInfo.CacheInfo) -> Bool {
        if let old = self.etag, let new = otherInfo.etag {
            return old == new
        }
        else if let old = lastModified, let new = otherInfo.lastModified {
            return old == new
        }
        else {
            return false
        }
    }
    
}
