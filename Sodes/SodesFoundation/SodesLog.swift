//
//  SodesLog.swift
//  SodesFoundation
//
//  Created by Jared Sinclair on 7/25/16.
//
//

import Foundation

public func SodesLog(_ input: Any = "", file: String = #file, function: String = #function, line: Int = #line) {
    #if DEBUG
        print("\n\(NSDate())\n\(file):\n\(function)() Line \(line)\n\(input)\n\n")
    #endif
}
