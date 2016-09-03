//
//  Errors.swift
//  SodesAudio
//
//  Created by Jared Sinclair on 8/20/16.
//
//

import Foundation

public enum SodesAudioError: Error {
    case unknown
    case byteRangeAccessNotSupported(HTTPURLResponse)
}
