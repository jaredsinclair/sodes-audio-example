//
//  HTTPOperation.swift
//  SodesFoundation
//
//  Created by Jared Sinclair on 7/9/16.
//
//

import Foundation

public class HTTPOperation: WorkOperation {
    
    public enum Result {
        case data(Data, HTTPURLResponse)
        case error(HTTPURLResponse?, Error?)
    }
    
    private let internals: HTTPOperationInternals
    
    public init(url: URL, session: URLSession, completion: @escaping (Result) -> Void) {
        let internals = HTTPOperationInternals(
            request: URLRequest(url: url),
            session: session
        )
        self.internals = internals
        super.init {
            completion(internals.result)
        }
    }
    
    public init(request: URLRequest, session: URLSession, completion: @escaping (Result) -> Void) {
        let internals = HTTPOperationInternals(
            request: request,
            session: session
        )
        self.internals = internals
        super.init {
            completion(internals.result)
        }
    }
    
    override public func work(_ finish: @escaping () -> Void) {
        internals.task = internals.session.dataTask(with: internals.request) { (data, response, error) in
            guard !self.isCancelled else {return}
            // TODO: [MEDIUM] Consider how to handle redirects (POST vs GET e.g.)
            guard let r = response as? HTTPURLResponse, let data = data, 200 <= r.statusCode, r.statusCode <= 299 else
            {
                self.internals.result = .error((response as? HTTPURLResponse), error)
                finish()
                return
            }
            self.internals.result = .data(data, r)
            finish()
        }
        internals.task?.resume()
    }
    
    override public func cancel() {
        internals.task?.cancel()
        super.cancel()
    }
    
}

private class HTTPOperationInternals {
    
    let request: URLRequest
    let session: URLSession
    var task: URLSessionDataTask?
    var result: HTTPOperation.Result = .error(nil, nil)
    
    init(request: URLRequest, session: URLSession) {
        self.request = request
        self.session = session
    }
    
}
