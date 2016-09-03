//
//  ResourceLoaderSubrequest.swift
//  SodesAudio
//
//  Created by Jared Sinclair on 8/5/16.
//
//

import Foundation
import SodesFoundation

/// An intermediate struct useful for calculating which subranges of data can be
/// read from a scratch file versus downloaded from the Internet.
struct ResourceLoaderSubrequest: Equatable, CustomStringConvertible {
    
    /// The sources from which data can be read.
    enum Source {
        case scratchFile
        case network
    }
    
    /// The source from which the data must be read.
    let source: Source
    
    /// The subrequest range (only a portion of the entire requested range).
    let range: ByteRange
    
    /// Description for debugging.
    var description: String {
        var s = "ResourceLoaderSubrequest("
        switch source {
        case .scratchFile:
            s += ".scratchFile"
        case .network:
            s += ".network"
        }
        s += ", "
        s += range.description
        s += ")"
        return s
    }
}

func ==(lhs: ResourceLoaderSubrequest, rhs: ResourceLoaderSubrequest) -> Bool {
    return lhs.source == rhs.source && lhs.range == rhs.range
}

extension ResourceLoaderSubrequest {
    
    /// Creates an array of subrequests. It will create scratch file subrequests
    /// for data already loaded in `scratchFileRanges`, and network subrequests
    /// for any gaps in the requested range not found in `scratchFileRanges`.
    static func subrequests(requestedRange: ByteRange, scratchFileRanges: [ByteRange]) -> [ResourceLoaderSubrequest] {
        
        var subrequests: [ResourceLoaderSubrequest] = []
        
        let intersectingRanges = scratchFileRanges
            .filter{$0.intersects(requestedRange)}
            .sorted{$0.lowerBound < $1.lowerBound}
        
        if intersectingRanges.isEmpty {
            let networkSubrequest = ResourceLoaderSubrequest(source: .network, range: requestedRange)
            subrequests.append(networkSubrequest)
            return subrequests
        }
        
        var cursor = requestedRange.lowerBound
        
        var nextRangeIndex = 0
        
        while cursor < requestedRange.upperBound && nextRangeIndex < intersectingRanges.count {
            
            let nextRange = intersectingRanges[nextRangeIndex]
            let position = nextRange.relativePosition(of: cursor)
            
            switch position {
            case .before:
                let lowerBound = cursor
                let upperBound = min(nextRange.lowerBound, requestedRange.upperBound)
                let networkRequest = ResourceLoaderSubrequest(
                    source: .network,
                    range: (lowerBound..<upperBound)
                )
                subrequests.append(networkRequest)
                cursor = upperBound
            case .inside:
                let lowerBound = cursor
                let upperBound = min(nextRange.upperBound, requestedRange.upperBound)
                let scratchFileRequest = ResourceLoaderSubrequest(
                    source: .scratchFile,
                    range: (lowerBound..<upperBound)
                )
                subrequests.append(scratchFileRequest)
                cursor = upperBound
                nextRangeIndex += 1
            case .after:
                assertionFailure("An intersecting range's upper bound should not be lower than the requested range's lower bound. This is a programmer error. In production this will fall back to a single network request for the entire requested range.")
                return [ResourceLoaderSubrequest(source: .network, range: requestedRange)]
            }
            
        }
        
        if cursor < requestedRange.upperBound {
            let lowerBound = cursor
            let upperBound = requestedRange.upperBound
            let networkRequest = ResourceLoaderSubrequest(
                source: .network,
                range: (lowerBound..<upperBound)
            )
            subrequests.append(networkRequest)
        }
        
        return subrequests
    }
    
}
