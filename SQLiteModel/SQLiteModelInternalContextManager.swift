//
//  SQLiteModelInternalContextManager.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 12/26/15.
//  Copyright © 2015 jhurray. All rights reserved.
//

import Foundation
import SQLite

internal typealias Meta = SQLiteModelInternalContextManager

internal class SQLiteModelInternalContextManager {
    
    
    private var internalStates = [String : SQLiteModelInternalContext]()
    private static let sharedInstance = SQLiteModelInternalContextManager()
    
    internal static func tableNameForModel(modelType: Any.Type) -> String {
        let context = self.internalContextForModel(modelType)
        return context.tableName
    }
    
    internal static func tableForModel(modelType: Any.Type) -> Table {
        let context = self.internalContextForModel(modelType)
        return context.table
    }
    
    internal static func localIDExpressionForModel(modelType: Any.Type) -> Expression<Int64> {
        let context = self.internalContextForModel(modelType)
        return context.localIDExpression
    }
    
    internal static func localCreatedAtExpressionForModel(modelType: Any.Type) -> Expression<NSDate> {
        let context = self.internalContextForModel(modelType)
        return context.localCreatedAtExpression
    }
    
    internal static func localUpdatedAtExpressionForModel(modelType: Any.Type) -> Expression<NSDate> {
        let context = self.internalContextForModel(modelType)
        return context.localUpdatedAtExpression
    }
    
    internal static func localCreatedAtForModel(modelType: Any.Type, hash: Int64) -> NSDate? {
        guard let instanceContext =  self.localInstanceContextFor(modelType, hash: hash) else {return nil}
        return instanceContext.localCreatedAt
    }
    
    internal static func localUpdatedAtForModel(modelType: Any.Type, hash: Int64) -> NSDate? {
        guard let instanceContext =  self.localInstanceContextFor(modelType, hash: hash) else {return nil}
        return instanceContext.localUpdatedAt
    }
    
    internal static func createLocalInstanceContextFor(modelType: Any.Type, row: Row) {
        var context = self.internalContextForModel(modelType)
        let _ = context.createInstanceContextFromModel(row)
        self.sharedInstance.internalStates[context.tableName] = context
    }
    
    internal static func updateLocalInstanceContextForModel(modelType: Any.Type, hash: Int64) throws -> Void {
        guard var instanceContext =  self.localInstanceContextFor(modelType, hash: hash) else {
            throw SQLiteModelError.UpdateError
        }
        var context = self.internalContextForModel(modelType)
        instanceContext.localUpdatedAt = NSDate()
        context.localContextOfInstances[hash] = instanceContext
        self.sharedInstance.internalStates[context.tableName] = context
    }
    
    
    // MARK: Private
    
    private static func internalContextForModel(modelType: Any.Type) -> SQLiteModelInternalContext {
        return self.sharedInstance.internalContextForModel(modelType)
    }
    
    private func internalContextForModel(modelType: Any.Type) -> SQLiteModelInternalContext {
        let key = self.stringFromModel(modelType)
        if let context = self.internalStates[key] {
            return context
        }
        else {
            let context = SQLiteModelInternalContext(modelType: modelType)
            self.internalStates[key] = context
            return context
        }
    }
    
    private static func localInstanceContextFor(modelType: Any.Type, hash: Int64) -> SQLiteModelInternalInstanceContext? {
        var context = self.sharedInstance.internalContextForModel(modelType)
        guard let instanceContext = context.localContextOfInstances[hash] else  {return nil}
        return instanceContext
    }
    
    private func stringFromModel(modelType: Any.Type) -> String {
        return String(modelType)
    }
}

internal struct SQLiteModelInternalContext {
    
    let table: Table
    let localIDExpression: Expression<Int64>
    let localCreatedAtExpression: Expression<NSDate>
    let localUpdatedAtExpression: Expression<NSDate>
    let tableName: String
    var localContextOfInstances: [Int64 : SQLiteModelInternalInstanceContext]
    
    private struct Keys {
        static let localID = "sqlmdl_localID"
        static let localCreatedAt = "sqlmdl_localCreatedAt"
        static let localUpdatedAt = "sqlmdl_localUpdatedAt"
    }
    
    internal init(modelType: Any.Type) {
        self.tableName = String(modelType)
        self.table = Table(self.tableName)
        self.localIDExpression = Expression<Int64>(Keys.localID)
        self.localCreatedAtExpression = Expression<NSDate>(Keys.localCreatedAt)
        self.localUpdatedAtExpression = Expression<NSDate>(Keys.localUpdatedAt)
        self.localContextOfInstances = [Int64 : SQLiteModelInternalInstanceContext]()
    }
    
    mutating internal func createInstanceContextFromModel(row: Row) -> SQLiteModelInternalInstanceContext {
        let instanceContext = SQLiteModelInternalInstanceContext(row: row, context: self)
        let localID = row[self.localIDExpression]
        self.localContextOfInstances[localID] = instanceContext
        return instanceContext
    }
    
}

struct SQLiteModelInternalInstanceContext {
    
    var localCreatedAt: NSDate
    var localUpdatedAt: NSDate
    
    init() {
        self.localCreatedAt = NSDate()
        self.localUpdatedAt = NSDate()
    }
    
    internal init(row: Row, context: SQLiteModelInternalContext) {
        self.localCreatedAt = row[context.localCreatedAtExpression]
        self.localUpdatedAt = row[context.localUpdatedAtExpression]
    }
}