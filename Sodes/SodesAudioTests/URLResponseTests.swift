//
//  URLResponseTests.swift
//  SodesAudioTests
//
//  Created by Jared Sinclair on 8/20/16.
//
//

import XCTest
@testable import SodesAudio

class URLResponseTests: XCTestCase {
    
    func test_itExtractsResponseRangeAndTotalExpectedContentLength() {
        let url = URL(string: "http://example.com/audio.mp3")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: 206,
            httpVersion: nil,
            headerFields: [
                "Content-Range": "bytes 100-199/444444"
            ]
        )
        let expectedRange: ByteRange = (100..<200)
        XCTAssertEqual(response?.sodes_responseRange, expectedRange)
        XCTAssertEqual(response?.sodes_expectedContentLength, 444444)
    }
    
}
