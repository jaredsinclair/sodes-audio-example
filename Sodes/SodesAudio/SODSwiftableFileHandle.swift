//
//  SODSwiftableFileHandle.swift
//  SodesAudio
//
//  Created by Jared Sinclair on 8/6/16.
//
//

import Foundation
import SodesFoundation
import SwiftableFileHandle

extension SODSwiftableFileHandle {
    
    func read(from range: ByteRange) throws -> Data {
        do {
            let data = try readData(
                fromLocation: UInt64(range.lowerBound),
                length: UInt64(range.length)
            )
            return data
        } catch {
            throw(error)
        }
    }
    
    func write(_ data: Data, over range: ByteRange) throws {
        do {
            try write(data, at: UInt64(range.lowerBound))
        } catch {
            throw(error)
        }
    }
    
}
