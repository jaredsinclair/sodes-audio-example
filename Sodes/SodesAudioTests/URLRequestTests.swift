//
//  URLRequestTests.swift
//  SodesAudioTests
//
//  Created by Jared Sinclair on 8/19/16.
//
//

import XCTest
@testable import SodesAudio

class URLRequestTests: XCTestCase {
    
    func test_itCreatesADataRequest() {
        let url = URL(string: "http://example.com/audio.mp3")!
        let range: ByteRange = (100..<200)
        let request = URLRequest.dataRequest(from: url, for: range)
        XCTAssertEqual(request.cachePolicy, .reloadIgnoringLocalCacheData)
        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.allHTTPHeaderFields!["Range"], "bytes=100-199")
    }
    
    func test_itExtractsRequestedByteRange() {
        let url = URL(string: "http://example.com/audio.mp3")!
        let range: ByteRange = (100..<200)
        let request = URLRequest.dataRequest(from: url, for: range)
        XCTAssertEqual(request.byteRange, range)
    }
    
}
