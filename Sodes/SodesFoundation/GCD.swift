//
//  GCD.swift
//  SodesFoundation
//
//  Created by Jared Sinclair on 7/9/16.
//
//

import Foundation

public func onMainQueue(_ block: @escaping () -> Void) {
    DispatchQueue.main.async(execute: block)
}

public func onMainQueueSyncIfPossible(_ block: @escaping () -> Void) {
    if OperationQueue.current === OperationQueue.main {
        block()
    } else {
        DispatchQueue.main.async(execute: block)
    }
}

public func onGlobalQueue(_ block: @escaping () -> Void) {
    DispatchQueue.global().async(execute: block)
}
