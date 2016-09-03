//
//  ByteRangeTests.swift
//  SodesAudioTests
//
//  Created by Jared Sinclair on 8/5/16.
//
//

import XCTest
@testable import SodesAudio

class ByteRangeTests: XCTestCase {
    
    // MARK: General
    
    func testItCreatesAValidRange() {
        let range: ByteRange = (0..<10)
        XCTAssertEqual(range.lowerBound, 0)
        XCTAssertEqual(range.upperBound, 10)
        XCTAssertEqual(range.lastValidIndex, 9)
        XCTAssertEqual(range.subdataRange, Range<Int>((0..<10)))
    }
    
    // MARK: Leading
    
    func testItComputesCorrectLeadingIntersections_SameStarts_DifferingEnds() {
        
        let a1: ByteRange = (0..<5)
        let b1: ByteRange = (0..<5)
        let expected1: ByteRange? = (0..<5)
        XCTAssertEqual(a1.leadingIntersection(in: b1), expected1)

        let a2: ByteRange = (0..<3)
        let b2: ByteRange = (0..<5)
        let expected2: ByteRange? = (0..<3)
        XCTAssertEqual(a2.leadingIntersection(in: b2), expected2)

        let a3: ByteRange = (0..<10)
        let b3: ByteRange = (0..<5)
        let expected3: ByteRange? = (0..<5)
        XCTAssertEqual(a3.leadingIntersection(in: b3), expected3)
        
        let a4: ByteRange = (0..<5)
        let b4: ByteRange = (0..<10)
        let expected4: ByteRange? = (0..<5)
        XCTAssertEqual(a4.leadingIntersection(in: b4), expected4)
        
    }
    
    func testItComputesCorrectLeadingIntersections_DifferingStarts_SameEnds() {
        
        let a1: ByteRange = (5..<10)
        let b1: ByteRange = (0..<10)
        let expected1: ByteRange? = nil
        XCTAssertEqual(a1.leadingIntersection(in: b1), expected1)
        
        let a2: ByteRange = (0..<10)
        let b2: ByteRange = (5..<10)
        let expected2: ByteRange? = (5..<10)
        XCTAssertEqual(a2.leadingIntersection(in: b2), expected2)
        
    }
    
    func testItComputesCorrectLeadingIntersections_DifferingStarts_DifferingEnds() {
        
        let a1: ByteRange = (0..<20)
        let b1: ByteRange = (5..<10)
        let expected1: ByteRange? = (5..<10)
        XCTAssertEqual(a1.leadingIntersection(in: b1), expected1)
        
        let a2: ByteRange = (5..<10)
        let b2: ByteRange = (0..<20)
        let expected2: ByteRange? = nil
        XCTAssertEqual(a2.leadingIntersection(in: b2), expected2)
        
        let a3: ByteRange = (10..<20)
        let b3: ByteRange = (5..<10)
        let expected3: ByteRange? = nil
        XCTAssertEqual(a3.leadingIntersection(in: b3), expected3)
        
        let a4: ByteRange = (5..<10)
        let b4: ByteRange = (10..<20)
        let expected4: ByteRange? = nil
        XCTAssertEqual(a4.leadingIntersection(in: b4), expected4)
        
    }
    
    func testItComputesCorrectLeadingIntersections_OffByOnes() {
        
        let a1: ByteRange = (0..<2)
        let b1: ByteRange = (1..<2)
        let expected1: ByteRange? = (1..<2)
        XCTAssertEqual(a1.leadingIntersection(in: b1), expected1)
        
        let a2: ByteRange = (1..<2)
        let b2: ByteRange = (0..<2)
        let expected2: ByteRange? = nil
        XCTAssertEqual(a2.leadingIntersection(in: b2), expected2)
        
        let a3: ByteRange = (1..<2)
        let b3: ByteRange = (0..<1)
        let expected3: ByteRange? = nil
        XCTAssertEqual(a3.leadingIntersection(in: b3), expected3)
        
        let a4: ByteRange = (0..<1)
        let b4: ByteRange = (1..<2)
        let expected4: ByteRange? = nil
        XCTAssertEqual(a4.leadingIntersection(in: b4), expected4)
        
    }
    
    // MARK: Trailing
    
    func testItComputesCorrectTrailingRanges_SameStarts_DifferingEnds() {
        
        let a1: ByteRange = (0..<5)
        let b1: ByteRange = (0..<5)
        let expected1: ByteRange? = nil
        XCTAssertEqual(a1.trailingRange(in: b1), expected1)
        
        let a2: ByteRange = (0..<3)
        let b2: ByteRange = (0..<5)
        let expected2: ByteRange? = (3..<5)
        XCTAssertEqual(a2.trailingRange(in: b2), expected2)
        
        let a3: ByteRange = (0..<10)
        let b3: ByteRange = (0..<5)
        let expected3: ByteRange? = nil
        XCTAssertEqual(a3.trailingRange(in: b3), expected3)
        
        let a4: ByteRange = (0..<5)
        let b4: ByteRange = (0..<10)
        let expected4: ByteRange? = (5..<10)
        XCTAssertEqual(a4.trailingRange(in: b4), expected4)
        
    }
    
    func testItComputesCorrectTrailingRanges_DifferingStarts_SameEnds() {
        
        let a1: ByteRange = (5..<10)
        let b1: ByteRange = (0..<10)
        let expected1: ByteRange? = nil
        XCTAssertEqual(a1.trailingRange(in: b1), expected1)
        
        let a2: ByteRange = (0..<10)
        let b2: ByteRange = (5..<10)
        let expected2: ByteRange? = nil
        XCTAssertEqual(a2.trailingRange(in: b2), expected2)
        
    }
    
    func testItComputesCorrectTrailingRanges_DifferingStarts_DifferingEnds() {
        
        let a1: ByteRange = (0..<20)
        let b1: ByteRange = (5..<10)
        let expected1: ByteRange? = nil
        XCTAssertEqual(a1.trailingRange(in: b1), expected1)
        
        let a2: ByteRange = (5..<10)
        let b2: ByteRange = (0..<20)
        let expected2: ByteRange? = nil
        XCTAssertEqual(a2.trailingRange(in: b2), expected2)
        
        let a3: ByteRange = (10..<20)
        let b3: ByteRange = (5..<10)
        let expected3: ByteRange? = nil
        XCTAssertEqual(a3.trailingRange(in: b3), expected3)
        
        let a4: ByteRange = (5..<10)
        let b4: ByteRange = (10..<20)
        let expected4: ByteRange? = nil
        XCTAssertEqual(a4.trailingRange(in: b4), expected4)
        
    }
    
    func testItComputesCorrectTrailingRanges_OffByOnes() {
        
        let a1: ByteRange = (0..<2)
        let b1: ByteRange = (1..<2)
        let expected1: ByteRange? = nil
        XCTAssertEqual(a1.trailingRange(in: b1), expected1)
        
        let a2: ByteRange = (1..<2)
        let b2: ByteRange = (0..<2)
        let expected2: ByteRange? = nil
        XCTAssertEqual(a2.trailingRange(in: b2), expected2)
        
        let a3: ByteRange = (1..<2)
        let b3: ByteRange = (0..<1)
        let expected3: ByteRange? = nil
        XCTAssertEqual(a3.trailingRange(in: b3), expected3)
        
        let a4: ByteRange = (0..<1)
        let b4: ByteRange = (1..<2)
        let expected4: ByteRange? = nil
        XCTAssertEqual(a4.trailingRange(in: b4), expected4)
        
    }
    
    // MARK: Satisfaction
    
    func testItComputesSatisfaction_SameStarts_DifferingEnds() {
        
        let a1: ByteRange = (0..<5)
        let b1: ByteRange = (0..<5)
        XCTAssertTrue(a1.fullySatisfies(b1))
        
        let a2: ByteRange = (0..<3)
        let b2: ByteRange = (0..<5)
        XCTAssertFalse(a2.fullySatisfies(b2))
        
        let a3: ByteRange = (0..<10)
        let b3: ByteRange = (0..<5)
        XCTAssertTrue(a3.fullySatisfies(b3))
        
        let a4: ByteRange = (0..<5)
        let b4: ByteRange = (0..<10)
        XCTAssertFalse(a4.fullySatisfies(b4))
        
    }
    
    func testItComputesSatisfaction_DifferingStarts_SameEnds() {
        
        let a1: ByteRange = (5..<10)
        let b1: ByteRange = (0..<10)
        XCTAssertFalse(a1.fullySatisfies(b1))
        
        let a2: ByteRange = (0..<10)
        let b2: ByteRange = (5..<10)
        XCTAssertTrue(a2.fullySatisfies(b2))
        
    }
    
    func testItComputesSatisfaction_DifferingStarts_DifferingEnds() {
        
        let a1: ByteRange = (0..<20)
        let b1: ByteRange = (5..<10)
        XCTAssertTrue(a1.fullySatisfies(b1))
        
        let a2: ByteRange = (5..<10)
        let b2: ByteRange = (0..<20)
        XCTAssertFalse(a2.fullySatisfies(b2))
        
        let a3: ByteRange = (10..<20)
        let b3: ByteRange = (5..<10)
        XCTAssertFalse(a3.fullySatisfies(b3))
        
        let a4: ByteRange = (5..<10)
        let b4: ByteRange = (10..<20)
        XCTAssertFalse(a4.fullySatisfies(b4))
        
    }
    
    func testItComputesSatisfaction_OffByOnes() {
        
        let a1: ByteRange = (0..<2)
        let b1: ByteRange = (1..<2)
        XCTAssertTrue(a1.fullySatisfies(b1))
        
        let a2: ByteRange = (1..<2)
        let b2: ByteRange = (0..<2)
        XCTAssertFalse(a2.fullySatisfies(b2))
        
        let a3: ByteRange = (1..<2)
        let b3: ByteRange = (0..<1)
        XCTAssertFalse(a3.fullySatisfies(b3))
        
        let a4: ByteRange = (0..<1)
        let b4: ByteRange = (1..<2)
        XCTAssertFalse(a4.fullySatisfies(b4))
        
    }
    
    // MARK: Continuity
    
    func testItDetectsContinuity_SameStarts_DifferingEnds() {
        
        let a1: ByteRange = (0..<5)
        let b1: ByteRange = (0..<5)
        XCTAssertFalse(a1.isContiguousWith(b1))
        
        let a2: ByteRange = (0..<3)
        let b2: ByteRange = (0..<5)
        XCTAssertFalse(a2.isContiguousWith(b2))
        
        let a3: ByteRange = (0..<10)
        let b3: ByteRange = (0..<5)
        XCTAssertFalse(a3.isContiguousWith(b3))
        
        let a4: ByteRange = (0..<5)
        let b4: ByteRange = (0..<10)
        XCTAssertFalse(a4.isContiguousWith(b4))
        
    }
    
    func testItDetectsContinuity_DifferingStarts_SameEnds() {
        
        let a1: ByteRange = (5..<10)
        let b1: ByteRange = (0..<10)
        XCTAssertFalse(a1.isContiguousWith(b1))
        
        let a2: ByteRange = (0..<10)
        let b2: ByteRange = (5..<10)
        XCTAssertFalse(a2.isContiguousWith(b2))
        
    }
    
    func testItDetectsContinuity_DifferingStarts_DifferingEnds() {
        
        let a1: ByteRange = (0..<20)
        let b1: ByteRange = (5..<10)
        XCTAssertFalse(a1.isContiguousWith(b1))
        
        let a2: ByteRange = (5..<10)
        let b2: ByteRange = (0..<20)
        XCTAssertFalse(a2.isContiguousWith(b2))
        
        let a3: ByteRange = (10..<20)
        let b3: ByteRange = (5..<10)
        XCTAssertTrue(a3.isContiguousWith(b3))
        
        let a4: ByteRange = (5..<10)
        let b4: ByteRange = (10..<20)
        XCTAssertTrue(a4.isContiguousWith(b4))
        
    }
    
    func testItDetectsContinuity_OffByOnes() {
        
        let a1: ByteRange = (0..<2)
        let b1: ByteRange = (1..<2)
        XCTAssertFalse(a1.isContiguousWith(b1))
        
        let a2: ByteRange = (1..<2)
        let b2: ByteRange = (0..<2)
        XCTAssertFalse(a2.isContiguousWith(b2))
        
        let a3: ByteRange = (1..<2)
        let b3: ByteRange = (0..<1)
        XCTAssertTrue(a3.isContiguousWith(b3))
        
        let a4: ByteRange = (0..<1)
        let b4: ByteRange = (1..<2)
        XCTAssertTrue(a4.isContiguousWith(b4))
        
    }
    
    // MARK: Combination
    
    func testItCombinesArraysOfRanges_nonOverlapping() {
        
        var input: [ByteRange];
        var expected: [ByteRange]
        var combination: [ByteRange]

        input = []
        expected = []
        combination = combine(input)
        XCTAssertEqual(combination, expected)
        
        input = [(0..<2)]
        expected = [(0..<2)]
        combination = combine(input)
        XCTAssertEqual(combination, expected)
        
        input = [(0..<2), (8..<10)]
        expected = [(0..<2), (8..<10)]
        combination = combine(input)
        XCTAssertEqual(combination, expected)
        
        input = [(0..<2), (2..<10)]
        expected = [(0..<10)]
        combination = combine(input)
        XCTAssertEqual(combination, expected)
        
        input = [(0..<4), (8..<10), (3..<9)]
        expected = [(0..<10)]
        combination = combine(input)
        XCTAssertEqual(combination, expected)
        
        input = [(0..<4), (10..<30), (20..<40), (90..<100)]
        expected = [(0..<4), (10..<40), (90..<100)]
        combination = combine(input)
        XCTAssertEqual(combination, expected)
        
        input = [(20..<40), (10..<30), (90..<100), (0..<4)]
        expected = [(0..<4), (10..<40), (90..<100)]
        combination = combine(input)
        XCTAssertEqual(combination, expected)
        
        input = [(0..<1), (2..<3)]
        expected = [(0..<1), (2..<3)]
        combination = combine(input)
        XCTAssertEqual(combination, expected)
        
        input = [(5..<10), (3..<11)]
        expected = [(3..<11)]
        combination = combine(input)
        XCTAssertEqual(combination, expected)
        
    }
    
    func testItCombinesArraysOfRanges_overlapping() {
        
        var input: [ByteRange];
        var expected: [ByteRange]
        var combination: [ByteRange]

        input = [(0..<10), (0..<10), (20..<40), (20..<40)]
        expected = [(0..<10), (20..<40)]
        combination = combine(input)
        XCTAssertEqual(combination, expected)
        
    }
    
    // MARK: Relative Position
    
    func testItYieldsCorrectRelativePositions() {
        let range: ByteRange = (10..<20)
        XCTAssertEqual(range.relativePosition(of: 0), ByteRangeIndexPosition.before)
        XCTAssertEqual(range.relativePosition(of: 9), ByteRangeIndexPosition.before)
        XCTAssertEqual(range.relativePosition(of: 10), ByteRangeIndexPosition.inside)
        XCTAssertEqual(range.relativePosition(of: 11), ByteRangeIndexPosition.inside)
        XCTAssertEqual(range.relativePosition(of: 19), ByteRangeIndexPosition.inside)
        XCTAssertEqual(range.relativePosition(of: 20), ByteRangeIndexPosition.after)
        XCTAssertEqual(range.relativePosition(of: 21), ByteRangeIndexPosition.after)
    }
    
}
