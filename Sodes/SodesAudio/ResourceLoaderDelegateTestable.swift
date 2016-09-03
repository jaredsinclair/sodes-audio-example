//
//  ResourceLoaderDelegateTestable.swift
//  SodesAudio
//
//  Created by Jared Sinclair on 8/19/16.
//
//

import Foundation
import AVFoundation
import CommonCryptoSwift
import SodesFoundation
import SwiftableFileHandle

enum ContentInfoRequestDisposition {
    case useSimulatedResponse(contentLength: Int64)
    case useActualResponse
    
    /// Should return `.useSimulatedResponse` if the metadata cache has a non-
    /// nil expected length that is greater than zero, and if either that length
    /// is equal to the current scratch file info's expected length or the
    /// scratch file info's length is nil.
    static func disposition(using metaDataCache: MetadataCache?, url: URL, currentCacheInfo: ScratchFileInfo.CacheInfo) -> ContentInfoRequestDisposition {
        
        if let length = metaDataCache?.expectedLengthInBytes(for: url),
            length > 0,
            (length == currentCacheInfo.contentLength || currentCacheInfo.contentLength == nil)
        {
            return .useSimulatedResponse(contentLength: length)
        } else {
            return .useActualResponse
        }
        
    }
    
}
