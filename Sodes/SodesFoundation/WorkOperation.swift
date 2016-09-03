//
//  WorkOperation.swift
//  SodesFoundation
//
//  Created by Jared Sinclair on 7/9/16.
//
//

import Foundation

open class WorkOperation: Operation {
    
    // MARK: Typealiases
    
    public typealias FinishHandler = () -> Void
    
    // MARK: Private/public Properties
    
    private let performQueue: DispatchQueue
    private let completion: () -> Void
    
    // MARK: Init
    
    public init(completion: @escaping () -> Void) {
        self.completion = completion
        self.performQueue = DispatchQueue(
            label: "com.niceboy.SodesCore.WorkOperation",
            qos: .background
        )
        super.init()
    }
    
    // MARK: Required Methods for Subclasses
    
    open func work(_ finish: @escaping () -> Void) {
        assertionFailure("Subclasses must override without calling super.")
    }
    
    // MARK: NSOperation Requirements
    
    override open func start() {
        guard !isCancelled else {return}
        markAsRunning()
        performQueue.async {
            self.work { (result) in
                onMainQueue {
                    guard !self.isCancelled else {return}
                    self.completion()
                    self.markAsFinished()
                }
            }
        }
    }
    
    private var _finished: Bool = false
    override open var isFinished: Bool {
        get { return _finished }
        set { _finished = newValue }
    }
    
    private var _executing: Bool = false
    override open var isExecuting: Bool {
        get { return _executing }
        set { _executing = newValue }
    }
    
    override open var isAsynchronous: Bool {
        return true
    }
    
    private func markAsRunning() {
        willChangeValue(for: .isExecuting)
        _executing = true
        didChangeValue(for: .isExecuting)
    }
    
    private func markAsFinished() {
        willChangeValue(for: .isExecuting)
        willChangeValue(for: .isFinished)
        _executing = false
        _finished = true
        didChangeValue(for: .isExecuting)
        didChangeValue(for: .isFinished)
    }
    
    private func willChangeValue(for key: OperationChangeKey) {
        self.willChangeValue(forKey: key.rawValue)
    }
    
    private func didChangeValue(for key: OperationChangeKey) {
        self.didChangeValue(forKey: key.rawValue)
    }
    
}

private enum OperationChangeKey: String {
    case isFinished
    case isExecuting
}
