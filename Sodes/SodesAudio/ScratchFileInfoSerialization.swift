//
//  ScratchFileInfoSerialization.swift
//  SodesAudio
//
//  Created by Jared Sinclair on 8/5/16.
//
//

import Foundation
import SodesFoundation

extension PropertyListSerialization {
    
    /// Converts the input values into a data object that can be serialized as a
    /// property list.
    static func representation(for byteRanges: [ByteRange], cacheInfo: ScratchFileInfo.CacheInfo) -> Data? {
        var plist: [String: AnyObject] = [
            "byteRanges": byteRanges.map{stringRepresentation(for: $0)} as NSArray
        ]
        if let length = cacheInfo.contentLength {
            plist["contentLength"] = NSNumber(value: length)
        }
        if let etag = cacheInfo.etag {
            plist["etag"] = etag as NSString
        }
        if let lastModified = cacheInfo.lastModified {
            plist["lastModified"] = lastModified as NSDate
        }
        return try? data(fromPropertyList: plist, format: .xml, options: 0)
    }
    
    /// Converts property list data into byte ranges and cache info.
    static func byteRangesAndCacheInfo(from representation: Data) -> ([ByteRange], ScratchFileInfo.CacheInfo)? {
        guard
        let value = try? propertyList(from: representation, format: nil), let plist = value as? [String: Any],
            let strings = plist["byteRanges"] as? [String]
            else
        {
            return nil
        }
        let byteRanges = strings.flatMap{range(from: $0)}
        let info = ScratchFileInfo.CacheInfo(
            contentLength: (plist["contentLength"] as? NSNumber)?.int64Value,
            etag: plist["etag"] as? String,
            lastModified: plist["lastModified"] as? Date
        )
        return (byteRanges, info)
    }
    
    /// Convenience method.
    private static func stringRepresentation(for range: ByteRange) -> String {
        return "\(range.lowerBound)..<\(range.upperBound)"
    }
    
    /// Convenience method.
    private static func range(from string: String) -> ByteRange? {
        let comps = string.components(separatedBy: "..<")
        if comps.count == 2 {
            if let l = Int64(comps[0]), let u = Int64(comps[1]) {
                return (l..<u)
            }
        }
        return nil
    }
    
}

extension FileManager {
    
    /// Saves the input values as a property list at `fileUrl`.
    func save(byteRanges: [ByteRange], cacheInfo: ScratchFileInfo.CacheInfo, to fileUrl: URL) -> Bool {
        if let data = PropertyListSerialization.representation(for: byteRanges, cacheInfo: cacheInfo) {
            do {
                try data.write(to: fileUrl, options: .atomic)
                return true
            } catch {
                SodesLog(error)
                return false
            }
        } else {
            return false
        }
    }
    
    /// Reads the values from a property list found at `fileUrl`.
    func readRanges(at fileUrl: URL) -> ([ByteRange], ScratchFileInfo.CacheInfo)? {
        if let data = try? Data(contentsOf: fileUrl) {
            return PropertyListSerialization.byteRangesAndCacheInfo(from: data)
        } else {
            return nil
        }
    }
    
}
