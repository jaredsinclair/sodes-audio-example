//
//  Throttle.swift
//  SodesFoundation
//
//  Created by Jared Sinclair on 8/11/16.
//
//

import Foundation

public class Throttle {
    
    public typealias Action = () -> Void
    
    fileprivate let serialQueue: OperationQueue
    fileprivate var pendingAction: Action?
    fileprivate var hasTakenActionAtLeastOnce = false
    fileprivate var timer: Timer?
    fileprivate var timerTarget: TimerTarget! {
        didSet { assert(oldValue == nil) }
    }
    
    public init(minimumInterval: TimeInterval, qualityOfService: QualityOfService) {
        serialQueue = {
            let queue = OperationQueue()
            queue.qualityOfService = qualityOfService
            queue.maxConcurrentOperationCount = 1
            return queue
        }()
        timerTarget = TimerTarget(delegate: self)
        timer = {
            let timer = Timer(
                timeInterval: minimumInterval,
                target: timerTarget,
                selector: #selector(TimerTarget.timerFired),
                userInfo: nil,
                repeats: true
            )
            timer.tolerance = minimumInterval * 0.5
            RunLoop.main.add(timer, forMode: .commonModes)
            return timer
        }()
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    public func enqueue(immediately: Bool = false, action: Action) {
        let op = BlockOperation { [weak self] in
            guard let this = self else {return}
            if !this.hasTakenActionAtLeastOnce || immediately {
                this.hasTakenActionAtLeastOnce = true
                this.pendingAction = nil
                action()
            } else {
                this.pendingAction = action
            }
        }
        op.queuePriority = immediately ? .veryHigh : .normal
        serialQueue.addOperation(op)
    }
    
}

extension Throttle: TimerTargetDelegate {
    
    fileprivate func timerFired(for: TimerTarget) {
        serialQueue.addOperation { [weak self] in
            guard let this = self else {return}
            guard let action = this.pendingAction else {return}
            this.pendingAction = nil
            action()
        }
    }
    
}

private protocol TimerTargetDelegate: class {
    func timerFired(for: TimerTarget)
}

private class TimerTarget {
    
    weak var delegate: TimerTargetDelegate?
    
    init(delegate: TimerTargetDelegate) {
        self.delegate = delegate
    }
    
    @objc func timerFired(_ timer: Timer) {
        delegate?.timerFired(for: self)
    }
    
}
