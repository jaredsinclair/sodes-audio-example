//
//  URLResponse.swift
//  SodesAudio
//
//  Created by Jared Sinclair on 8/20/16.
//
//

import Foundation
import SodesFoundation

extension URLResponse {
    
    func cacheInfo(using formatter: RFC822Formatter) -> ScratchFileInfo.CacheInfo {
        return ScratchFileInfo.CacheInfo(
            contentLength: sodes_expectedContentLength,
            etag: etag,
            lastModified: lastModified(using: formatter)
        )
    }
    
    var sodes_isByteRangeEnabledResponse: Bool {
        return sodes_responseRange != nil
    }
    
    var sodes_responseRange: ByteRange? {
        guard let response = self as? HTTPURLResponse else {return nil}
        if let fullString = response.allHeaderFields["Content-Range"] as? String,
            let firstPart = fullString.characters.split(separator: "/").map({String($0)}).first
        {
            if let prefixRange = firstPart.range(of: "bytes ") {
                let rangeString = firstPart.substring(from: prefixRange.upperBound)
                let comps = rangeString.components(separatedBy: "-")
                let ints = comps.flatMap{Int64($0)}
                if ints.count == 2 {
                    return (ints[0]..<(ints[1]+1))
                }
            }
        }
        return nil
    }
    
    var sodes_expectedContentLength: Int64? {
        guard let response = self as? HTTPURLResponse else {return nil}
        if let rangeString = response.allHeaderFields["Content-Range"] as? String,
            let bytesString = rangeString.characters.split(separator: "/").map({String($0)}).last,
            let bytes = Int64(bytesString)
        {
            return bytes
        } else {
            return nil
        }
    }
    
    var etag: String? {
        guard let response = self as? HTTPURLResponse else {return nil}
        return response.allHeaderFields["Etag"] as? String
    }
    
    func lastModified(using formatter: RFC822Formatter) -> Date? {
        guard let response = self as? HTTPURLResponse else {return nil}
        if let string = response.allHeaderFields["Last-Modified"] as? String {
            return formatter.date(from: string)
        } else {
            return nil
        }
    }
    
}
