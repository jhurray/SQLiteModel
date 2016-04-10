//
//  SyncManager.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 4/8/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import Foundation
import Dispatch

internal typealias Queue = dispatch_queue_t

class SyncManager {
    
    private static let sharedInstance = SyncManager()
    private var queues = [String: Queue]()
    private static let queueLock = NSLock()
    
    private static func queueForModel<V: SQLiteModel>(modelType: V.Type) -> Queue {
        self.queueLock.lock()
        let key = String(modelType)
        if let queue = self.sharedInstance.queues[key] {
            self.queueLock.unlock()
            return queue
        }
        else {
            let queue = dispatch_queue_create("sqlitemodel.background.\(key)", DISPATCH_QUEUE_SERIAL)
            self.sharedInstance.queues[key] = queue
            self.queueLock.unlock()
            return queue
        }
    }
    
    static func sync<V: SQLiteModel>(modelType: V.Type, block: Void -> Void) {
        let queue = self.queueForModel(modelType)
        dispatch_sync(queue, block)
    }
}
