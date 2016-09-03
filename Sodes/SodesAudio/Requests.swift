//
//  Requests.swift
//  SodesAudio
//
//  Created by Jared Sinclair on 8/9/16.
//
//

import Foundation
import AVFoundation

protocol Request: class {
    var resourceUrl: URL {get}
    var loadingRequest: AVAssetResourceLoadingRequest {get}
    
    func cancel()
}

class ContentInfoRequest: Request {
    
    let resourceUrl: URL
    let loadingRequest: AVAssetResourceLoadingRequest
    let infoRequest: AVAssetResourceLoadingContentInformationRequest
    let task: URLSessionTask
    
    init(resourceUrl: URL, loadingRequest: AVAssetResourceLoadingRequest, infoRequest: AVAssetResourceLoadingContentInformationRequest, task: URLSessionTask) {
        self.resourceUrl = resourceUrl
        self.loadingRequest = loadingRequest
        self.infoRequest = infoRequest
        self.task = task
    }
    
    func cancel() {
        task.cancel()
        if !loadingRequest.isCancelled && !loadingRequest.isFinished {
            loadingRequest.finishLoading()
        }
    }
    
}

class DataRequest: Request {
    
    let resourceUrl: URL
    let loadingRequest: AVAssetResourceLoadingRequest
    let dataRequest: AVAssetResourceLoadingDataRequest
    let loader: DataRequestLoader
    
    init(resourceUrl: URL, loadingRequest: AVAssetResourceLoadingRequest, dataRequest: AVAssetResourceLoadingDataRequest, loader: DataRequestLoader) {
        self.resourceUrl = resourceUrl
        self.loadingRequest = loadingRequest
        self.dataRequest = dataRequest
        self.loader = loader
    }
    
    func cancel() {
        loader.cancel()
        if !loadingRequest.isCancelled && !loadingRequest.isFinished {
            loadingRequest.finishLoading()
        }
    }
    
}
