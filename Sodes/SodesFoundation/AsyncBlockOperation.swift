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
    public typealias WorkBlock = (@escaping FinishHandler) -> Void
    
    private let workBlock: WorkBlock
    
    public init(work: @escaping WorkBlock) {
        self.workBlock = work
        super.init{}
    }
    
    public init(work: @escaping WorkBlock, completion: @escaping () -> Void) {
        self.workBlock = work
        super.init(completion: completion)
    }
    
    override public func work(_ finish: @escaping FinishHandler) {
        workBlock(finish)
    }
    
}
