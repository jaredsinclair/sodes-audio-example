//
//  NSObject.swift
//  SodesAudio
//
//  Created by Jared Sinclair on 7/10/16.
//
//

import Foundation

internal extension NSObject {
    
    func add(observer: NSObject, for keypaths: [String], options: NSKeyValueObservingOptions = .new, context: UnsafeMutableRawPointer) {
        for path in keypaths {
            addObserver(observer, forKeyPath: path, options: options, context: context)
        }
    }
    
    func remove(observer: NSObject, for keypaths: [String], options: NSKeyValueObservingOptions = .new, context: UnsafeMutableRawPointer) {
        for path in keypaths {
            removeObserver(observer, forKeyPath: path, context: context)
        }
    }
    
}
