//
//  ResourceLoaderDelegateTests.swift
//  SodesAudioTests
//
//  Created by Jared Sinclair on 8/19/16.
//
//

import XCTest
@testable import SodesAudio

class TestMetadataCache: MetadataCache {
    let expectedLength: Int64?
    init(expectedLength: Int64?) {
        self.expectedLength = expectedLength
    }
    func expectedLengthInBytes(for resourceUrl: URL) -> Int64? {
        return expectedLength
    }
}

class ResourceLoaderDelegateTests: XCTestCase {
    
    // MARK: ContentInfoRequestDisposition
    
    let zeroCache = TestMetadataCache(expectedLength: 0)
    let nilCache = TestMetadataCache(expectedLength: nil)
    let kiloCache = TestMetadataCache(expectedLength: 1024)
    
    func test_itReturnsCorrectInfoDisposition_Variant1() {
        let url = URL(string: "http://example.com/audio.mp3")!
        let date = Date()
        let info = ScratchFileInfo.CacheInfo(
            contentLength: 1000, etag: "etag", lastModified: date
        )
        let d = ContentInfoRequestDisposition.disposition(using: nil, url: url, currentCacheInfo: info)
        switch d {
        case .useActualResponse:
            // success
            break
        case .useSimulatedResponse(_):
            XCTFail()

        }
    }
    
    func test_itReturnsCorrectInfoDisposition_Variant2() {
        let url = URL(string: "http://example.com/audio.mp3")!
        let date = Date()
        let info = ScratchFileInfo.CacheInfo(
            contentLength: 512, etag: "etag", lastModified: date
        )
        let d = ContentInfoRequestDisposition.disposition(using: kiloCache, url: url, currentCacheInfo: info)
        switch d {
        case .useActualResponse:
            // success
            break
        case .useSimulatedResponse(_):
            XCTFail()
        }
    }
    
    func test_itReturnsCorrectInfoDisposition_Variant3() {
        let url = URL(string: "http://example.com/audio.mp3")!
        let date = Date()
        let info = ScratchFileInfo.CacheInfo(
            contentLength: 1024, etag: "etag", lastModified: date
        )
        let d = ContentInfoRequestDisposition.disposition(using: kiloCache, url: url, currentCacheInfo: info)
        switch d {
        case .useActualResponse:
            XCTFail()
        case .useSimulatedResponse(let length):
            XCTAssertEqual(1024, length)
        }
    }
    
    func test_itReturnsCorrectInfoDisposition_Variant4() {
        let url = URL(string: "http://example.com/audio.mp3")!
        let date = Date()
        let info = ScratchFileInfo.CacheInfo(
            contentLength: 0, etag: "etag", lastModified: date
        )
        let d = ContentInfoRequestDisposition.disposition(using: nil, url: url, currentCacheInfo: info)
        switch d {
        case .useActualResponse:
            // success
            break
        case .useSimulatedResponse(_):
            XCTFail()
        }
    }
    
    func test_itReturnsCorrectInfoDisposition_Variant5() {
        let url = URL(string: "http://example.com/audio.mp3")!
        let date = Date()
        let info = ScratchFileInfo.CacheInfo(
            contentLength: 0, etag: "etag", lastModified: date
        )
        let d = ContentInfoRequestDisposition.disposition(using: nilCache, url: url, currentCacheInfo: info)
        switch d {
        case .useActualResponse:
            // success
            break
        case .useSimulatedResponse(_):
            XCTFail()
        }
    }
    
    func test_itReturnsCorrectInfoDisposition_Variant6() {
        let url = URL(string: "http://example.com/audio.mp3")!
        let date = Date()
        let info = ScratchFileInfo.CacheInfo(
            contentLength: 0, etag: "etag", lastModified: date
        )
        let d = ContentInfoRequestDisposition.disposition(using: zeroCache, url: url, currentCacheInfo: info)
        switch d {
        case .useActualResponse:
            // success
            break
        case .useSimulatedResponse(_):
            XCTFail()
        }
    }
    
    func test_itReturnsCorrectInfoDisposition_Variant7() {
        let url = URL(string: "http://example.com/audio.mp3")!
        let date = Date()
        let info = ScratchFileInfo.CacheInfo(
            contentLength: nil, etag: "etag", lastModified: date
        )
        let d = ContentInfoRequestDisposition.disposition(using: nilCache, url: url, currentCacheInfo: info)
        switch d {
        case .useActualResponse:
            // success
            break
        case .useSimulatedResponse(_):
            XCTFail()
        }
    }
    
    func test_itReturnsCorrectInfoDisposition_Variant8() {
        let url = URL(string: "http://example.com/audio.mp3")!
        let date = Date()
        let info = ScratchFileInfo.CacheInfo(
            contentLength: nil, etag: "etag", lastModified: date
        )
        let d = ContentInfoRequestDisposition.disposition(using: zeroCache, url: url, currentCacheInfo: info)
        switch d {
        case .useActualResponse:
            // success
            break
        case .useSimulatedResponse(_):
            XCTFail()
        }
    }
    
}
