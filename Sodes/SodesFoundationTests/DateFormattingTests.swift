//
//  DateFormattingTests.swift
//  Sodes
//
//  Created by Jared Sinclair on 8/17/16.
//
//

import XCTest
@testable import SodesFoundation

class DateFormattingTests: XCTestCase {
    
    func test_itParsesDateStringWithWeekday() {
        let expected = Date(timeIntervalSince1970: 1468130424)
        let formatter = RFC822Formatter.sharedFormatter
        let actual = formatter.date(from: "Sun, 10 Jul 2016 06:00:24 +0000")
        XCTAssertEqual(expected, actual)
    }
    
    func test_itParsesDateStringWithoutWeekday() {
        let expected = Date(timeIntervalSince1970: 1468130424)
        let formatter = RFC822Formatter.sharedFormatter
        let actual = formatter.date(from: "10 Jul 2016 06:00:24 +0000")
        XCTAssertEqual(expected, actual)
    }
    
}
