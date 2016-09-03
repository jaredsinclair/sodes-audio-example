//
//  URL.swift
//  SodesAudio
//
//  Created by Jared Sinclair on 7/24/16.
//
//

import Foundation

internal extension URL {
    
    /// Returns true if the receiver's path extension is equal to `pathExt`.
    func hasPathExtension(_ pathExt: String) -> Bool {
        guard let comps = URLComponents(url: self, resolvingAgainstBaseURL: false) else {return false}
        return (comps.path as NSString).pathExtension == pathExt
    }
    
    /// Adds the scheme prefix to a copy of the receiver.
    func convertToRedirectURL(prefix: String) -> URL? {
        guard var comps = URLComponents(url: self, resolvingAgainstBaseURL: false) else {return nil}
        guard let scheme = comps.scheme else {return nil}
        comps.scheme = prefix + scheme
        return comps.url
    }
    
    /// Removes the scheme prefix from a copy of the receiver.
    func convertFromRedirectURL(prefix: String) -> URL? {
        guard var comps = URLComponents(url: self, resolvingAgainstBaseURL: false) else {return nil}
        guard let scheme = comps.scheme else {return nil}
        comps.scheme = scheme.replacingOccurrences(of: prefix, with: "")
        return comps.url
    }
    
}
