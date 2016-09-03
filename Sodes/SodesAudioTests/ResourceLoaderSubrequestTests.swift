//
//  ResourceLoaderSubrequestTests.swift
//  SodesAudioTests
//
//  Created by Jared Sinclair on 8/6/16.
//
//

import XCTest
@testable import SodesAudio

class ResourceLoaderSubrequestTests: XCTestCase {
    
    func testItProducesOneBigNetworkRequestWhenNoRangesAreFound() {
        let requestedRange: ByteRange = (10..<600)
        let subrequests = ResourceLoaderSubrequest.subrequests(
            requestedRange: requestedRange,
            scratchFileRanges: [],
            initialChunkCacheRange: nil
        )
        XCTAssertEqual(subrequests.count, 1)
        XCTAssertEqual(subrequests[0], ResourceLoaderSubrequest(source: .network, range: requestedRange))
    }
    
    func testItProducesOneBigScratchFileRequestWhenTheFullRangeIsSatisfied() {
        let requestedRange: ByteRange = (10..<600)
        let subrequests = ResourceLoaderSubrequest.subrequests(
            requestedRange: requestedRange,
            scratchFileRanges: [(0..<1000)],
            initialChunkCacheRange: nil
        )
        XCTAssertEqual(subrequests.count, 1)
        XCTAssertEqual(subrequests[0], ResourceLoaderSubrequest(source: .scratchFile, range: requestedRange))
    }
    
    func testItProducesCorrectSubrequests_variant1() {
        let requestedRange: ByteRange = (10..<600)
        let subrequests = ResourceLoaderSubrequest.subrequests(
            requestedRange: requestedRange,
            scratchFileRanges: [(100..<200), (300..<400), (500..<550)],
            initialChunkCacheRange: nil
        )
        XCTAssertEqual(subrequests.count, 7)
        let expected = [
            ResourceLoaderSubrequest(source: .network,      range: (010..<100)),
            ResourceLoaderSubrequest(source: .scratchFile,  range: (100..<200)),
            ResourceLoaderSubrequest(source: .network,      range: (200..<300)),
            ResourceLoaderSubrequest(source: .scratchFile,  range: (300..<400)),
            ResourceLoaderSubrequest(source: .network,      range: (400..<500)),
            ResourceLoaderSubrequest(source: .scratchFile,  range: (500..<550)),
            ResourceLoaderSubrequest(source: .network,      range: (550..<600)),
            ]
        XCTAssertEqual(subrequests, expected)
    }
    
    func testItProducesCorrectSubrequests_variant2() {
        let requestedRange: ByteRange = (10..<600)
        let subrequests = ResourceLoaderSubrequest.subrequests(
            requestedRange: requestedRange,
            scratchFileRanges: [(100..<200), (300..<400), (500..<600)],
            initialChunkCacheRange: nil
        )
        XCTAssertEqual(subrequests.count, 6)
        let expected = [
            ResourceLoaderSubrequest(source: .network,      range: (010..<100)),
            ResourceLoaderSubrequest(source: .scratchFile,  range: (100..<200)),
            ResourceLoaderSubrequest(source: .network,      range: (200..<300)),
            ResourceLoaderSubrequest(source: .scratchFile,  range: (300..<400)),
            ResourceLoaderSubrequest(source: .network,      range: (400..<500)),
            ResourceLoaderSubrequest(source: .scratchFile,  range: (500..<600)),
            ]
        XCTAssertEqual(subrequests, expected)
    }
    
    func testItProducesCorrectSubrequests_variant3() {
        let requestedRange: ByteRange = (0..<3)
        let subrequests = ResourceLoaderSubrequest.subrequests(
            requestedRange: requestedRange,
            scratchFileRanges: [(1..<2)],
            initialChunkCacheRange: nil
        )
        XCTAssertEqual(subrequests.count, 3)
        let expected = [
            ResourceLoaderSubrequest(source: .network,      range: (0..<1)),
            ResourceLoaderSubrequest(source: .scratchFile,  range: (1..<2)),
            ResourceLoaderSubrequest(source: .network,      range: (2..<3)),
            ]
        XCTAssertEqual(subrequests, expected)
    }
    
    func testItProducesCorrectSubrequests_variant4() {
        let requestedRange: ByteRange = (1..<2)
        let subrequests = ResourceLoaderSubrequest.subrequests(
            requestedRange: requestedRange,
            scratchFileRanges: [(0..<3)],
            initialChunkCacheRange: nil
        )
        XCTAssertEqual(subrequests.count, 1)
        let expected = [
            ResourceLoaderSubrequest(source: .scratchFile,  range: (1..<2)),
            ]
        XCTAssertEqual(subrequests, expected)
    }
    
    func testItProducesCorrectSubrequests_variant5() {
        let requestedRange: ByteRange = (0..<10)
        let subrequests = ResourceLoaderSubrequest.subrequests(
            requestedRange: requestedRange,
            scratchFileRanges: [(0..<5)],
            initialChunkCacheRange: nil
        )
        XCTAssertEqual(subrequests.count, 2)
        let expected = [
            ResourceLoaderSubrequest(source: .scratchFile,  range: (0..<5)),
            ResourceLoaderSubrequest(source: .network,      range: (5..<10)),
            ]
        XCTAssertEqual(subrequests, expected)
    }
    
    func testItProducesCorrectSubrequests_variant6() {
        let requestedRange: ByteRange = (2..<10)
        let subrequests = ResourceLoaderSubrequest.subrequests(
            requestedRange: requestedRange,
            scratchFileRanges: [(0..<2), (2..<5), (4..<10)],
            initialChunkCacheRange: nil
        )
        XCTAssertEqual(subrequests.count, 2)
        let expected = [
            ResourceLoaderSubrequest(source: .scratchFile,  range: (2..<5)),
            ResourceLoaderSubrequest(source: .scratchFile,  range: (5..<10)),
            ]
        XCTAssertEqual(subrequests, expected)
    }
    
    func testItProducesCorrectSubrequests_variant7() {
        let requestedRange: ByteRange = (0..<10)
        let subrequests = ResourceLoaderSubrequest.subrequests(
            requestedRange: requestedRange,
            scratchFileRanges: [(2..<10)],
            initialChunkCacheRange: (0..<2)
        )
        XCTAssertEqual(subrequests.count, 2)
        let expected = [
            ResourceLoaderSubrequest(source: .initialChunkCache,  range: (0..<2)),
            ResourceLoaderSubrequest(source: .scratchFile,  range: (2..<10)),
            ]
        XCTAssertEqual(subrequests, expected)
    }
    
    func testItProducesCorrectSubrequests_variant8() {
        let requestedRange: ByteRange = (0..<10)
        let subrequests = ResourceLoaderSubrequest.subrequests(
            requestedRange: requestedRange,
            scratchFileRanges: [(7..<10)],
            initialChunkCacheRange: (0..<2)
        )
        XCTAssertEqual(subrequests.count, 3)
        let expected = [
            ResourceLoaderSubrequest(source: .initialChunkCache,  range: (0..<2)),
            ResourceLoaderSubrequest(source: .network,  range: (2..<7)),
            ResourceLoaderSubrequest(source: .scratchFile,  range: (7..<10)),
            ]
        XCTAssertEqual(subrequests, expected)
    }
    
    func testItProducesCorrectSubrequests_variant10() {
        let requestedRange: ByteRange = (0..<10)
        let subrequests = ResourceLoaderSubrequest.subrequests(
            requestedRange: requestedRange,
            scratchFileRanges: [(3..<10)],
            initialChunkCacheRange: (0..<5)
        )
        XCTAssertEqual(subrequests.count, 2)
        let expected = [
            ResourceLoaderSubrequest(source: .initialChunkCache,  range: (0..<5)),
            ResourceLoaderSubrequest(source: .scratchFile,  range: (5..<10)),
            ]
        XCTAssertEqual(subrequests, expected)
    }
    
    func testItProducesCorrectSubrequests_variant11() {
        let requestedRange: ByteRange = (10..<20)
        let subrequests = ResourceLoaderSubrequest.subrequests(
            requestedRange: requestedRange,
            scratchFileRanges: [(13..<20)],
            initialChunkCacheRange: (0..<5)
        )
        XCTAssertEqual(subrequests.count, 2)
        let expected = [
            ResourceLoaderSubrequest(source: .network,  range: (10..<13)),
            ResourceLoaderSubrequest(source: .scratchFile,  range: (13..<20)),
            ]
        XCTAssertEqual(subrequests, expected)
    }
    
    func testItProducesCorrectSubrequests_variant12() {
        let requestedRange: ByteRange = (10..<20)
        let subrequests = ResourceLoaderSubrequest.subrequests(
            requestedRange: requestedRange,
            scratchFileRanges: [(13..<20)],
            initialChunkCacheRange: (0..<15)
        )
        XCTAssertEqual(subrequests.count, 2)
        let expected = [
            ResourceLoaderSubrequest(source: .initialChunkCache,  range: (10..<15)),
            ResourceLoaderSubrequest(source: .scratchFile,  range: (15..<20)),
            ]
        XCTAssertEqual(subrequests, expected)
    }

}
