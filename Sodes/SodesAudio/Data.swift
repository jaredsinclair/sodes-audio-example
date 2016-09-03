//
//  Data.swift
//  SodesAudio
//
//  Created by Jared Sinclair on 8/19/16.
//
//

import Foundation

extension Data {
    
    /// Convenience method for checking if the receiver contains enough data to
    /// satisfy the byte range request. This method assumes that the receiver is
    /// data received from an HTTP byte range request, and that the receiver's
    /// first index corresponds to `range`'s first index.
    func byteRangeResponseSubdata(in range: ByteRange) -> Data? {
        if Int64(count) >= range.length {
            return subdata(in: (0..<Int(range.length)))
        } else {
            return nil
        }
    }
    
}
