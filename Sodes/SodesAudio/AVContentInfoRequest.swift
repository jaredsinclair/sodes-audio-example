//
//  AVContentInfoRequest.swift
//  SodesAudio
//
//  Created by Jared Sinclair on 7/24/16.
//
//

import Foundation
import AVFoundation
import MobileCoreServices

internal extension AVAssetResourceLoadingContentInformationRequest {
    
    func update(with response: URLResponse) {
        
        if let response = response as? HTTPURLResponse {
            
            // TODO: [MEDIUM] Obtain the actual content type.
            contentType = "public.mp3"
            
            if let length = response.sodes_expectedContentLength {
                contentLength = length
            }
            
            if let acceptRanges = response.allHeaderFields["Accept-Ranges"] as? String,
                acceptRanges == "bytes"
            {
                isByteRangeAccessSupported = true
            } else {
                isByteRangeAccessSupported = false
            }
        }
        else {
            assertionFailure("Invalid URL Response.")
        }
    }
    
}


