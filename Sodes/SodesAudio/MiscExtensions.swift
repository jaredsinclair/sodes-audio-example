//
//  MiscExtensions.swift
//  SodesAudio
//
//  Created by Jared Sinclair on 7/16/16.
//
//

import Foundation
import AVFoundation

internal let preferredTimescale: Int32 = 10000

internal extension UInt {
    static func withInterval(_ i: TimeInterval?) -> UInt? {
        if let i = i {
            return UInt(i)
        } else {
            return nil
        }
    }
}

internal extension TimeInterval {
    var asCMTime: CMTime {
        return CMTimeMakeWithSeconds(self, preferredTimescale)
    }
}

internal extension CMTime {
    var asTimeInterval: TimeInterval? {
        if isNumeric {
            return CMTimeGetSeconds(self)
        } else {
            return nil
        }
    }
}

internal extension AVPlayer {
    
    var isPlaying: Bool {
        return error == nil && rate != 0 && currentItem != nil
    }
    
    var isPaused: Bool {
        return error == nil && rate == 0 && currentItem != nil
    }
    
}
