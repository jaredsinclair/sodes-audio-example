//
//  DataTests.swift
//  SodesAudioTests
//
//  Created by Jared Sinclair on 8/19/16.
//
//

import XCTest
@testable import SodesAudio

class DataTests: XCTestCase {
    
    func test_itReturnsSubdataForValidResponse_Variant1() {
        let data = Data(bytes: [0,1,2,3,4,5,6,7,8,9])
        let range: ByteRange = (0..<10)
        let subdata = data.byteRangeResponseSubdata(in: range)
        XCTAssertEqual(subdata, data)
    }
    
    func test_itReturnsSubdataForValidResponse_Variant2() {
        let data = Data(bytes: [0,1,2,3,4,5,6,7,8,9])
        let range: ByteRange = (100..<110)
        let subdata = data.byteRangeResponseSubdata(in: range)
        XCTAssertEqual(subdata, data)
    }
    
    func test_itReturnsNilForAnInvalidResponse_Variant1() {
        let data = Data(bytes: [0,1,2,3,4,5,6,7,8,9])
        let range: ByteRange = (0..<100)
        let subdata = data.byteRangeResponseSubdata(in: range)
        XCTAssertNil(subdata)
    }
    
    func test_itReturnsNilForAnInvalidResponse_Variant2() {
        let data = Data(bytes: [0,1,2,3,4,5,6,7,8,9])
        let range: ByteRange = (100..<200)
        let subdata = data.byteRangeResponseSubdata(in: range)
        XCTAssertNil(subdata)
    }
    
}
