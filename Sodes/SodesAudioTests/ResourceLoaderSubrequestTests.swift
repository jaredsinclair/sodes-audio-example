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
            scratchFileRanges: []
        )
        XCTAssertEqual(subrequests.count, 1)
        XCTAssertEqual(subrequests[0], ResourceLoaderSubrequest(source: .network, range: requestedRange))
    }
    
    func testItProducesOneBigScratchFileRequestWhenTheFullRangeIsSatisfied() {
        let requestedRange: ByteRange = (10..<600)
        let subrequests = ResourceLoaderSubrequest.subrequests(
            requestedRange: requestedRange,
            scratchFileRanges: [(0..<1000)]
        )
        XCTAssertEqual(subrequests.count, 1)
        XCTAssertEqual(subrequests[0], ResourceLoaderSubrequest(source: .scratchFile, range: requestedRange))
    }
    
    func testItProducesCorrectSubrequests_variant1() {
        let requestedRange: ByteRange = (10..<600)
        let subrequests = ResourceLoaderSubrequest.subrequests(
            requestedRange: requestedRange,
            scratchFileRanges: [(100..<200), (300..<400), (500..<550)]
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
            scratchFileRanges: [(100..<200), (300..<400), (500..<600)]
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
            scratchFileRanges: [(1..<2)]
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
            scratchFileRanges: [(0..<3)]
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
            scratchFileRanges: [(0..<5)]
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
            scratchFileRanges: [(0..<2), (2..<5), (4..<10)]
        )
        XCTAssertEqual(subrequests.count, 2)
        let expected = [
            ResourceLoaderSubrequest(source: .scratchFile,  range: (2..<5)),
            ResourceLoaderSubrequest(source: .scratchFile,  range: (5..<10)),
            ]
        XCTAssertEqual(subrequests, expected)
    }

}
