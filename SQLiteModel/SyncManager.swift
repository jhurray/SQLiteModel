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
    private var locks = [String: NSLock]()
    private static let queueLock = NSLock()
    private static let lockLock = NSLock()
    
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
    
    private static func lockForModel<V: SQLiteModel>(modelType: V.Type) -> NSLock {
        self.lockLock.lock()
        let key = String(modelType)
        if let lock = self.sharedInstance.locks[key] {
            self.lockLock.unlock()
            return lock
        }
        else {
            let lock = NSLock()
            self.sharedInstance.locks[key] = lock
            self.lockLock.unlock()
            return lock
        }
    }
    
    static func lock<V: SQLiteModel>(modelType: V.Type, block: Void -> Void) {
        let lock = self.lockForModel(modelType)
        lock.lock()
        block()
        lock.unlock()
    }
    
    static func sync<V: SQLiteModel>(modelType: V.Type, block: Void -> Void) {
        let queue = self.queueForModel(modelType)
        dispatch_sync(queue, block)
    }
    
    static func async<V: SQLiteModel>(modelType: V.Type, block: Void -> Void) {
        let queue = self.queueForModel(modelType)
        dispatch_async(queue, block)
    }
    
    typealias ExecuteBlock = Void throws -> Void
    typealias ErrorBlock = Void -> Void
    typealias MainBlock = Void -> Void
    
    static func async<V: SQLiteModel>(modelType: V.Type, execute: ExecuteBlock, onError: ErrorBlock) {
        let queue = self.queueForModel(modelType)
        dispatch_async(queue) {
            do {
                try execute()
            }
            catch {
                onError()
            }
        }
    }
    
    static func main(block: MainBlock) {
        dispatch_async(dispatch_get_main_queue(), block)
    }
    
    static func main(completion: Completion?, error: SQLiteModelError?) {
        self.main {
            if let completion = completion {
                completion(error)
            }
        }
    }
}
