//
//  DelegatedHTTPOperation.swift
//  SodesFoundation
//
//  Created by Jared Sinclair on 8/6/16.
//
//

import Foundation

public protocol HTTPOperationDataDelegate: class {
    func delegatedHTTPOperation(_ operation: DelegatedHTTPOperation, didReceiveResponse response: HTTPURLResponse)
    func delegatedHTTPOperation(_ operation: DelegatedHTTPOperation, didReceiveData data: Data)
}

public class DelegatedHTTPOperation: WorkOperation {
    
    public enum Result {
        case success(response: HTTPURLResponse, bytesExpected: Int64, bytesReceived: Int64)
        case error(HTTPURLResponse?, Error?)
    }
    
    public let request: URLRequest
    
    fileprivate let delegateQueue: OperationQueue
    fileprivate weak var dataDelegate: HTTPOperationDataDelegate?
    fileprivate let internals: DelegatedHTTPOperationInternals
    fileprivate var session: URLSession!
    fileprivate var task: URLSessionDataTask!
    
    fileprivate var finish: (() -> Void)?
    fileprivate var response: HTTPURLResponse? = nil
    fileprivate var bytesExpected: Int64 = 0
    fileprivate var bytesReceived: Int64 = 0
    
    public init(url: URL, configuration: URLSessionConfiguration = .default, dataDelegate: HTTPOperationDataDelegate, delegateQueue: OperationQueue, completion: @escaping (Result) -> Void) {
        assert(delegateQueue.maxConcurrentOperationCount == 1, "DelegatedHTTPOperation's delegate queue must be a serial queue.")
        let internals = DelegatedHTTPOperationInternals()
        self.internals = internals
        self.delegateQueue = delegateQueue
        self.dataDelegate = dataDelegate
        self.request = URLRequest(url: url)
        super.init { completion(internals.result) }
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: delegateQueue)
        self.task = session.dataTask(with: request)
    }
    
    public init(request: URLRequest, configuration: URLSessionConfiguration = .default, dataDelegate: HTTPOperationDataDelegate, delegateQueue: OperationQueue, completion: @escaping (Result) -> Void) {
        assert(delegateQueue.maxConcurrentOperationCount == 1, "DelegatedHTTPOperation's delegate queue must be a serial queue.")
        let internals = DelegatedHTTPOperationInternals()
        self.internals = internals
        self.delegateQueue = delegateQueue
        self.dataDelegate = dataDelegate
        self.request = request
        super.init { completion(internals.result) }
        self.session = URLSession(configuration: configuration, delegate: self, delegateQueue: delegateQueue)
        self.task = session.dataTask(with: request)
    }
    
    override public func work(_ finish: @escaping () -> Void) {
        self.finish = finish
        task.resume()
    }
    
    override public func cancel() {
        task.cancel()
        super.cancel()
    }
    
    fileprivate func invokeFinishHandler() {
        delegateQueue.addOperation { [weak self] in
            guard let this = self else {return}
            guard !this.isCancelled else {return}
            let handler = this.finish
            this.finish = nil
            handler?()
        }
    }
    
}

extension DelegatedHTTPOperation: URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        guard !isCancelled else {return}
        
        // TODO: [MEDIUM] Consider how to handle redirects (POST vs GET e.g.)
        guard let httpResponse = response as? HTTPURLResponse, 200 <= httpResponse.statusCode, httpResponse.statusCode <= 299 else
        {
            SodesLog("Invalid response received: \(response)")
            completionHandler(.cancel)
            internals.result = .error((response as? HTTPURLResponse), nil)
            invokeFinishHandler()
            return
        }
        
        self.response = httpResponse
        self.bytesExpected = httpResponse.contentLength
        SodesLog("self.bytesExpected: \(bytesExpected)\nresponse: \(httpResponse)")
        
        delegateQueue.addOperation { [weak self] in
            guard let this = self else {return}
            guard !this.isCancelled else {return}
            this.dataDelegate?.delegatedHTTPOperation(this, didReceiveResponse: httpResponse)
        }
        
        completionHandler(.allow)
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard !isCancelled else {return}
        bytesReceived += Int64(data.count)
        delegateQueue.addOperation { [weak self] in
            guard let this = self else {return}
            guard !this.isCancelled else {return}
            this.dataDelegate?.delegatedHTTPOperation(this, didReceiveData: data)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard !isCancelled else {return}
        if let response = self.response, error == nil {
            internals.result = .success(
                response: response,
                bytesExpected: bytesExpected,
                bytesReceived: bytesReceived
            )
        } else {
            internals.result = .error(response, error)
        }
        invokeFinishHandler()
    }
    
}

fileprivate class DelegatedHTTPOperationInternals {
    var result: DelegatedHTTPOperation.Result = .error(nil, nil)
}

fileprivate extension HTTPURLResponse {
    var contentLength: Int64 {
        if let s = allHeaderFields["Content-Length"] as? String {
            return Int64(s) ?? 0
        }
        return allHeaderFields["Content-Length"] as? Int64 ?? 0
    }
}
