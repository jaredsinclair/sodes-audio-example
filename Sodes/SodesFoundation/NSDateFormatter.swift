//
//  NSDateFormatter.swift
//  SodesCore
//
//  Created by Jared Sinclair on 7/10/16.
//
//

import Foundation

public class RFC822Formatter {
    
    public static let sharedFormatter = RFC822Formatter()
    
    private let formatterWithWeekdays: DateFormatter
    private let formatterWithoutWeekdays: DateFormatter
    private let lock = NSLock()
    
    public init() {
        formatterWithWeekdays = DateFormatter.RFC822Formatter(includeWeekdays: true)
        formatterWithoutWeekdays = DateFormatter.RFC822Formatter(includeWeekdays: false)
    }
    
    public func string(from date: Date) -> String? {
        lock.lock()
        let withWeekdays = formatterWithWeekdays.string(from: date)
        lock.unlock()
        return withWeekdays
    }
    
    public func date(from string: String) -> Date? {
        
        // TODO: [MEDIUM] Ensure that we don't need a more efficient means of knowing
        // which formatter to try first (or not at all), etc.
        
        lock.lock()
        let withWeekdays = formatterWithWeekdays.date(from: string)
        lock.unlock()
        if let with = withWeekdays {
            return with
        }
        
        lock.lock()
        let withoutWeekdays = formatterWithoutWeekdays.date(from: string)
        lock.unlock()
        return withoutWeekdays
        
    }
    
}

private extension DateFormatter {
    
    static func RFC822Formatter(includeWeekdays include: Bool) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if include {
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        } else {
            formatter.dateFormat = "dd MMM yyyy HH:mm:ss z"
        }
        return formatter
    }
    
}
