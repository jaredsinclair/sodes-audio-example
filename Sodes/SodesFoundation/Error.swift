//
//  Error.swift
//  Sodes
//
//  Created by Jared Sinclair on 8/30/16.
//
//

import Foundation

public func description(of optionalError: Error?) -> String {
    if let error = optionalError {
        let type = type(of: error)
        if type == NSError.self {
            let nsError = error as NSError
            return nsError.domain + "_\(nsError.code)"
        } else {
            return String(describing: type) + "." + String(describing: error)
        }
    } else {
        return "nil"
    }
}
