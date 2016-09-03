//
//  AsyncBlockOperation.swift
//  SodesFoundation
//
//  Created by Jared Sinclair on 7/9/16.
//
//

import Foundation

public class AsyncBlockOperation: WorkOperation {
    
    public typealias FinishHandler = () -> Void
    public typealias WorkBlock = (FinishHandler) -> Void
    
    private let workBlock: WorkBlock
    
    public init(work: WorkBlock) {
        self.workBlock = work
        super.init{}
    }
    
    public init(work: WorkBlock, completion: @escaping () -> Void) {
        self.workBlock = work
        super.init(completion: completion)
    }
    
    override public func work(_ finish: FinishHandler) {
        workBlock(finish)
    }
    
}
