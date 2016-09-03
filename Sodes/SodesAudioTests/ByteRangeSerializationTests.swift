//
//  ByteRangeSerializationTests.swift
//  SodesAudioTests
//
//  Created by Jared Sinclair on 8/5/16.
//
//

import XCTest
import SodesFoundation
@testable import SodesAudio

class ByteRangeSerializationTests: XCTestCase {
    
    // MARK: JSON Serialization

    func testItConvertsByteRangesToData() {
        XCTAssertNotNil(PropertyListSerialization.representation(for: [], cacheInfo: .none))
        XCTAssertNotNil(PropertyListSerialization.representation(for:[(0..<1)], cacheInfo: .none))
        XCTAssertNotNil(PropertyListSerialization.representation(for:[(0..<1), (1..<2), (2..<3)], cacheInfo: .none))
    }
    
    func testItConvertsByteRangesToDataAndBackAgain() {
        
        var input: [ByteRange]!
        var data: Data!
        var output: ([ByteRange], ScratchFileInfo.CacheInfo)!
        
        input = []
        data = PropertyListSerialization.representation(for:input, cacheInfo: .none)
        output = PropertyListSerialization.byteRangesAndCacheInfo(from: data)
        XCTAssertEqual(input, output.0)
        
        input = [(0..<1)]
        data = PropertyListSerialization.representation(for:input, cacheInfo: .none)
        output = PropertyListSerialization.byteRangesAndCacheInfo(from: data)
        XCTAssertEqual(input, output.0)
        
        input = [(0..<1), (1..<2), (2..<3)]
        data = PropertyListSerialization.representation(for:input, cacheInfo: .none)
        output = PropertyListSerialization.byteRangesAndCacheInfo(from: data)
        XCTAssertEqual(input, output.0)
        
    }
    
    // MARK: File Management
    
    func testItSavesByteRangesAndReadsThemBack() {
        let directory = FileManager.default.cachesDirectory()!
        let fileUrl = directory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let inputRanges: [ByteRange] = [(0..<1), (3..<10)]
        let inputDate = Date()
        let contentLength: Int64 = 2056
        let inputInfo = ScratchFileInfo.CacheInfo(
            contentLength: contentLength, etag: "e", lastModified: inputDate
        )
        XCTAssertTrue(FileManager.default.save(byteRanges: inputRanges, cacheInfo: inputInfo, to: fileUrl))
        let output = FileManager.default.readRanges(at: fileUrl)
        XCTAssertEqual(contentLength, output!.1.contentLength)
        XCTAssertEqual(inputRanges, output!.0)
        XCTAssertEqual("e", output!.1.etag)
        XCTAssertEqualWithAccuracy(inputDate.timeIntervalSince(output!.1.lastModified!), 0.0, accuracy: 1.0)
    }
    
    func testItSavesByteRangesTwiceAndReadsThemBack() {
        
        let directory = FileManager.default.cachesDirectory()!
        let fileUrl = directory.appendingPathComponent(NSUUID().uuidString, isDirectory: false)
        let inputRanges1: [ByteRange] = [(0..<1), (3..<10)]
        let inputRanges2: [ByteRange] = [(0..<1), (16..<20), (3..<10)]
        let contentLength: Int64 = 2056
        let inputDate = Date()
        let inputInfo = ScratchFileInfo.CacheInfo(
            contentLength: contentLength, etag: "e", lastModified: inputDate
        )
        
        XCTAssertTrue(FileManager.default.save(byteRanges: inputRanges1, cacheInfo: inputInfo, to: fileUrl))
        let output1 = FileManager.default.readRanges(at: fileUrl)
        XCTAssertEqual(contentLength, output1!.1.contentLength)
        XCTAssertEqual(inputRanges1, output1!.0)
        XCTAssertEqual("e", output1!.1.etag)
        XCTAssertEqualWithAccuracy(inputDate.timeIntervalSince(output1!.1.lastModified!), 0.0, accuracy: 1.0)
        
        XCTAssertTrue(FileManager.default.save(byteRanges: inputRanges2, cacheInfo: inputInfo, to: fileUrl))
        let output2 = FileManager.default.readRanges(at: fileUrl)
        XCTAssertEqual(contentLength, output2!.1.contentLength)
        XCTAssertEqual(inputRanges2, output2!.0)
        XCTAssertEqual("e", output2!.1.etag)
        XCTAssertEqualWithAccuracy(inputDate.timeIntervalSince(output2!.1.lastModified!), 0.0, accuracy: 1.0)
        
    }

}
