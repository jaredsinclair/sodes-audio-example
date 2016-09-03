//
//  DownloadOperation.swift
//  SodesFoundation
//
//  Created by Jared Sinclair on 7/9/16.
//
//

import Foundation

public class DownloadOperation: WorkOperation {
    
    public enum Result {
        case tempUrl(URL, HTTPURLResponse)
        case error(HTTPURLResponse?, Error?)
    }
    
    private let internals: DownloadOperationInternals
    
    public init(url: URL, session: URLSession, completion: @escaping (Result) -> Void) {
        let internals = DownloadOperationInternals(
            request: URLRequest(url: url),
            session: session
        )
        self.internals = internals
        super.init {
            completion(internals.result)
        }
    }
    
    public init(request: URLRequest, session: URLSession, completion: @escaping (Result) -> Void) {
        let internals = DownloadOperationInternals(
            request: request,
            session: session
        )
        self.internals = internals
        super.init {
            completion(internals.result)
        }
    }
    
    override public func work(_ finish: @escaping () -> Void) {
        internals.task = internals.session.downloadTask(with: internals.request) { (tempUrl, response, error) in
            guard !self.isCancelled else {return}
            // TODO: [MEDIUM] Consider how to handle redirects (POST vs GET e.g.)
            guard
                let r = response as? HTTPURLResponse,
                let tempUrl = tempUrl,
                200 <= r.statusCode && r.statusCode <= 299 else
            {
                self.internals.result = .error((response as? HTTPURLResponse), error)
                finish()
                return
            }
            self.internals.result = .tempUrl(tempUrl, r)
            finish()
        }
        internals.task?.resume()
    }
    
    override public func cancel() {
        internals.task?.cancel()
        super.cancel()
    }
    
}

private class DownloadOperationInternals {
    
    let request: URLRequest
    let session: URLSession
    var task: URLSessionDownloadTask?
    var result: DownloadOperation.Result = .error(nil, nil)
    
    init(request: URLRequest, session: URLSession) {
        self.request = request
        self.session = session
    }
    
}
