//
//  DelegatedHTTPOperationTests.swift
//  SodesFoundationTests
//
//  Created by Jared Sinclair on 8/7/16.
//
//

import XCTest
@testable import SodesFoundation

class DelegatedHTTPOperationTests: XCTestCase {
    
    var receivedBytes: Int64 = 0
    var delegateQueue: OperationQueue!
    
    override func setUp() {
        receivedBytes = 0
        delegateQueue = OperationQueue()
        delegateQueue.maxConcurrentOperationCount = 1
    }
    
    func testItFetchesAKnownGoodResource() {
        let url = URL(string: "http://jaredsinclair.com/img/pixel-jared.png")!
        let exp = expectation(description: "It fetches a known good resource.")
        let op = DelegatedHTTPOperation(
            url: url,
            configuration: .default,
            dataDelegate: self,
            delegateQueue: delegateQueue,
            completion: { (result) in
                XCTAssertEqual(OperationQueue.current, OperationQueue.main)
                switch result {
                case .success(_, let expected, let received):
                    XCTAssertEqual(expected, received)
                    XCTAssertEqual(self.receivedBytes, received)
                    break
                case .error(let r, let e):
                    SodesLog("response: \(r), error: \(e)")
                    XCTFail()
                    break
                }
                XCTAssertEqual(self.receivedBytes, 2134)
                exp.fulfill()
        })
        op.start()
        waitForExpectations(timeout: 10)
    }
    
}

extension DelegatedHTTPOperationTests: HTTPOperationDataDelegate {
    
    func delegatedHTTPOperation(_ operation: DelegatedHTTPOperation, didReceiveResponse response: HTTPURLResponse) {
        // no op
    }
    
    func delegatedHTTPOperation(_ operation: DelegatedHTTPOperation, didReceiveData data: Data) {
        XCTAssertEqual(OperationQueue.current, delegateQueue)
        receivedBytes += data.count
    }
    
}
