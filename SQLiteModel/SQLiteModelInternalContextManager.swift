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
    
    internal static func localInstanceContextForModel(modelType: Any.Type, hash: Int64) -> SQLiteModelInternalInstanceContext? {
        var context = self.sharedInstance.internalContextForModel(modelType)
        guard let instanceContext = context.localContextOfInstances[hash] else  {return nil}
        return instanceContext
    }
    
    // JHTODO make this better (throws? returns nil?)
    internal static func getValueForModel<V: Value>(modelType: Any.Type, hash: Int64, expression: Expression<V>) -> V {
        guard let value = self.getValueForModel(modelType, hash: hash, expression: Expression<V?>(expression)) else {
            fatalError("SQLiteModel Fatal Error: could not fetch value for expression: \(expression)")
        }
        return value
    }
    
    internal static func getValueForModel<V: Value>(modelType: Any.Type, hash: Int64, expression: Expression<V?>) -> V? {
        guard let instanceContext = self.localInstanceContextForModel(modelType, hash: hash) else {return nil}
        if let wrappedValue = instanceContext[expression.template] {
            return wrappedValue.value as? V
        }
        return instanceContext.row.get(expression)
    }
    
    internal static func getRelationshipForModel<V: SQLiteModel>(modelType: V.Type, hash: Int64, relationship: Relationship<V>) -> V {
        guard let value = self.getRelationshipForModel(modelType, hash: hash, relationship: Relationship<V?>(relationship)) else {
            fatalError("SQLiteModel Fatal Error: could not fetch value for relationship: \(relationship)")
        }
        return value
    }
    
    internal static func getRelationshipForModel<U: SQLiteModel, V: SQLiteModel>(modelType: U.Type, hash: Int64, relationship: Relationship<V?>) -> V? {
        
        guard let instanceContext = self.localInstanceContextForModel(modelType, hash: hash) else {return nil}
        if let wrappedValue = instanceContext[relationship.referenceExpression.template] {
            return wrappedValue.value as? V
        }
        guard let relationshipID = instanceContext.row.get(relationship.referenceExpression) else {
            return nil
        }
        do {
            let insance = try V.find(relationshipID)
            return insance
        }
        catch {
            return nil
        }
    }
    
    internal static func setValueForModel<V: Value>(modelType: Any.Type, hash: Int64, column: Expression<V>, value: V) -> Bool {
        return self.setValueForModel(modelType, hash: hash, column: Expression<V?>(column), value: value)
    }
    
    internal static func setValueForModel<V: Value>(modelType: Any.Type, hash: Int64, column: Expression<V?>, value: V?) -> Bool {
        guard var instanceContext = self.localInstanceContextForModel(modelType, hash: hash) else {return false}
        instanceContext[column.template] = ValueWrapper(value: value)
        instanceContext.setters.append(column <- value as Setter)
        var context = self.internalContextForModel(modelType)
        context.localContextOfInstances[hash] = instanceContext
        self.sharedInstance.internalStates[context.tableName] = context
        return true
    }
    
    internal static func setRelationshipForModel<V: SQLiteModel>(modelType: Any.Type, hash: Int64, column: Relationship<V>, value: V) -> Bool {
        return self.setRelationshipForModel(modelType, hash: hash, column: Relationship<V?>(column), value: value)
    }
    
    internal static func setRelationshipForModel<V: SQLiteModel>(modelType: Any.Type, hash: Int64, column: Relationship<V?>, value: V?) -> Bool {
        guard var instanceContext = self.localInstanceContextForModel(modelType, hash: hash) else {return false}
        instanceContext[column.referenceExpression.template] = ValueWrapper(value: value)
        instanceContext.setters.append(column <- value as Setter)
        var context = self.internalContextForModel(modelType)
        context.localContextOfInstances[hash] = instanceContext
        self.sharedInstance.internalStates[context.tableName] = context
        return true
    }
    
    internal static func localCreatedAtForModel(modelType: Any.Type, hash: Int64) -> NSDate? {
        guard let instanceContext = self.localInstanceContextForModel(modelType, hash: hash) else {return nil}
        return instanceContext.localCreatedAt
    }
    
    internal static func localUpdatedAtForModel(modelType: Any.Type, hash: Int64) -> NSDate? {
        guard let instanceContext = self.localInstanceContextForModel(modelType, hash: hash) else {return nil}
        return instanceContext.localUpdatedAt
    }
    
    internal static func settersForModel(modelType: Any.Type, hash: Int64) -> [Setter] {
        guard let instanceContext = self.localInstanceContextForModel(modelType, hash: hash) else {return []}
        return instanceContext.setters
    }
    
    internal static func createLocalInstanceContextFor(modelType: Any.Type, row: Row) {
        var context = self.internalContextForModel(modelType)
        let _ = context.createInstanceContextFromModel(row)
        self.sharedInstance.internalStates[context.tableName] = context
    }
    
    internal static func removeLocalInstanceContextFor(modelType: Any.Type, hash: Int64) {
        var context = self.internalContextForModel(modelType)
        let _ = context.localContextOfInstances.removeValueForKey(hash)
        self.sharedInstance.internalStates[context.tableName] = context
    }
    
    internal static func removeAllLocalInstanceContextsFor(modelType: Any.Type) {
        var context = self.internalContextForModel(modelType)
        let _ = context.localContextOfInstances.removeAll()
        self.sharedInstance.internalStates[context.tableName] = context
    }
    
    internal static func removeContextForModel(modelType: Any.Type) {
        self.sharedInstance.removeContextForModel(modelType)
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
    
    private func removeContextForModel(modelType: Any.Type) {
        let key = self.stringFromModel(modelType)
        self.internalStates.removeValueForKey(key)
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
    
    internal mutating func createInstanceContextFromModel(row: Row) -> SQLiteModelInternalInstanceContext {
        let instanceContext = SQLiteModelInternalInstanceContext(row: row, context: self)
        let localID = row[self.localIDExpression]
        self.localContextOfInstances[localID] = instanceContext
        return instanceContext
    }
}

internal struct ValueWrapper {
    let value: Any?
}

internal struct SQLiteModelInternalInstanceContext {
    
    var localCreatedAt: NSDate!
    var localUpdatedAt: NSDate!
    var row: Row!
    private  var columnValueMapping: [String : ValueWrapper]
    private(set) var setters: [Setter]
    
    internal init(row: Row, context: SQLiteModelInternalContext) {
        self.localCreatedAt = row[context.localCreatedAtExpression]
        self.localUpdatedAt = row[context.localUpdatedAtExpression]
        self.row = row
        self.setters = [Setter]()
        self.columnValueMapping = [String : ValueWrapper]()
    }
    
    internal subscript(key: String) -> ValueWrapper? {
        get {
            if let wrapper = self.columnValueMapping[key] {
                return wrapper
            }
            return nil
        }
        set(newValue) {
            self.columnValueMapping[key] = newValue
        }
    }
    
}