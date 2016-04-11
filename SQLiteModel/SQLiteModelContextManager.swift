//
//  SQLiteModelContextManager.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 12/26/15.
//  Copyright © 2015 jhurray. All rights reserved.
//

import Foundation
import SQLite

internal typealias Meta = SQLiteModelContextManager

internal class SQLiteModelContextManager {
    
    private var internalStates = [String : SQLiteModelContext]()
    private static let sharedInstance = SQLiteModelContextManager()
    
    internal static func tableForModel<V: SQLiteModel>(modelType: V.Type) -> Table {
        let context = self.internalContextForModel(modelType)
        return context.table
    }
    
    internal static func localIDExpressionForModel<V: SQLiteModel>(modelType: V.Type) -> Expression<Int64> {
        let context = self.internalContextForModel(modelType)
        return context.localIDExpression
    }
    
    internal static func localCreatedAtExpressionForModel<V: SQLiteModel>(modelType: V.Type) -> Expression<NSDate> {
        let context = self.internalContextForModel(modelType)
        return context.localCreatedAtExpression
    }
    
    internal static func localUpdatedAtExpressionForModel<V: SQLiteModel>(modelType: V.Type) -> Expression<NSDate> {
        let context = self.internalContextForModel(modelType)
        return context.localUpdatedAtExpression
    }
    
    internal static func localInstanceContextForModel<V: SQLiteModel>(modelType: V.Type, hash: Int64) -> SQLiteModelInstanceContext? {
        var context = self.sharedInstance.internalContextForModel(modelType)
        guard let instanceContext = context.localContextOfInstances[hash] else {
            return nil
        }
        return instanceContext
    }
    
    internal static func getValueForModel<U: SQLiteModel, V: Value>(modelType: U.Type, hash: Int64, expression: Expression<V?>) -> V? {
        guard let instanceContext = self.localInstanceContextForModel(modelType, hash: hash) else {
            return nil
        }
        if let wrappedValue = instanceContext[expression.template] {
            return wrappedValue.value as? V
        }
        return instanceContext.row.get(expression)
    }
    
    internal static func setValueForModel<U: SQLiteModel, V: Value>(modelType: U.Type, hash: Int64, column: Expression<V?>, value: V?) {
        guard var instanceContext = self.localInstanceContextForModel(modelType, hash: hash) else {
            return
        }
        instanceContext[column.template] = ValueWrapper(value: value)
        instanceContext.setters.append(column <- value as Setter)
        var context = self.internalContextForModel(modelType)
        context.localContextOfInstances[hash] = instanceContext
        self.setInternalContextForModel(modelType, context: context)
    }
    
    internal static func localCreatedAtForModel<V: SQLiteModel>(modelType: V.Type, hash: Int64) -> NSDate? {
        guard let instanceContext = self.localInstanceContextForModel(modelType, hash: hash) else {
            return nil
        }
        return instanceContext.localCreatedAt
    }
    
    internal static func localUpdatedAtForModel<V: SQLiteModel>(modelType: V.Type, hash: Int64) -> NSDate? {
        guard let instanceContext = self.localInstanceContextForModel(modelType, hash: hash) else {
            return nil
        }
        return instanceContext.localUpdatedAt
    }
    
    internal static func settersForModel<V: SQLiteModel>(modelType: V.Type, hash: Int64) -> [Setter] {
        guard let instanceContext = self.localInstanceContextForModel(modelType, hash: hash) else {
            return []
        }
        return instanceContext.setters
    }
    
    internal static func hasLocalInstanceContextFor<V: SQLiteModel>(modelType: V.Type, hash: Int64) -> Bool {
        let context = self.internalContextForModel(modelType)
        let instanceContext = context.localContextOfInstances[hash]
        return instanceContext != nil
    }
    
    internal static func createLocalInstanceContextFor<V: SQLiteModel>(modelType: V.Type, row: Row) {
        var context = self.internalContextForModel(modelType)
        let _ = context.createInstanceContextFromModel(row)
        self.setInternalContextForModel(modelType, context: context)
    }
    
    internal static func removeLocalInstanceContextFor<V: SQLiteModel>(modelType: V.Type, hash: Int64) {
        var context = self.internalContextForModel(modelType)
        context.deleteInstanceContextForHash(hash)
        self.setInternalContextForModel(modelType, context: context)
    }
    
    internal static func removeAllLocalInstanceContextsFor<V: SQLiteModel>(modelType: V.Type) {
        var context = self.internalContextForModel(modelType)
        let hashes = context.localContextOfInstances.keys
        for hash in hashes {
            context.deleteInstanceContextForHash(hash)
        }
        self.setInternalContextForModel(modelType, context: context)
    }
    
    internal static func removeContextForModel<V: SQLiteModel>(modelType: V.Type) {
        self.removeAllLocalInstanceContextsFor(modelType)
        let context = self.internalContextForModel(modelType)
        context.deleteLeftModelDependencies()
        self.sharedInstance.removeContextForModel(modelType)
    }
    
    // MARK: Private
    
    private static func internalContextForModel<V: SQLiteModel>(modelType: V.Type) -> SQLiteModelContext {
        return self.sharedInstance.internalContextForModel(modelType)
    }
    
    private static func setInternalContextForModel<V: SQLiteModel>(modelType: V.Type, context: SQLiteModelContext) {
        self.sharedInstance.setInternalContextForModel(modelType, context: context)
    }
    
    private func internalContextForModel<V: SQLiteModel>(modelType: V.Type) -> SQLiteModelContext {
        
        var _context: SQLiteModelContext?
        SyncManager.lock(modelType) {
            let key = V.tableName
            if let context = self.internalStates[key] {
                _context = context
            }
            else {
                let context = SQLiteModelContext(tableName: key)
                self.internalStates[key] = context
                _context = context
            }
        }
        return _context!
    }
    
    private func setInternalContextForModel<V: SQLiteModel>(modelType: V.Type, context: SQLiteModelContext) {
        SyncManager.lock(modelType) {
            let key = V.tableName
            self.internalStates[key] = context
        }
    }
    
    private func removeContextForModel<V: SQLiteModel>(modelType: V.Type) {
        SyncManager.lock(modelType) {
            let key = V.tableName
            self.internalStates.removeValueForKey(key)
        }
    }
}

// MARK: Relationships

extension Meta {
    
    // MARK: Create
    
    internal static func createRelationshipForModel<U: SQLiteModel, V: SQLiteModel>(modelType: U.Type, relationship: Relationship<V?>) {
        
        RelationshipReferenceTracker.setTemplate((U.self, V.self), template: relationship.template)
        
        if relationship.unique {
            UniqueSingularRelationship<U,V>.initialize()
            let _ = self.internalContextForModel(UniqueSingularRelationship<U,V>.self)
        }
        else {
            SingularRelationship<U,V>.initialize()
            let _ = self.internalContextForModel(SingularRelationship<U,V>.self)
        }
        
        func idsForColumn(column: Expression<Int64>, filterValue: Int64) -> [Int64] {
            RelationshipReferenceTracker.setTemplate((U.self, V.self), template: relationship.template)
            let context = self.internalContextForModel(SingularRelationship<U,V>.self)
            let ids = context.localContextOfInstances.filter({ (keyVal : (Int64, SQLiteModelInstanceContext)) -> Bool in
                if let id = Meta.getValueForModel(SingularRelationship<U,V>.self, hash: keyVal.0, expression: Expression<Int64?>(column)) {
                    return id == filterValue
                }
                return false
            }).map({ $0.0 })
            return ids
        }
        
        var leftModelContext = self.internalContextForModel(modelType)
        leftModelContext.addLeftModelDependency(SingularRelationship<U,V>.self) {
            RelationshipReferenceTracker.setTemplate((U.self, V.self), template: relationship.template)
            let _ = try? SingularRelationship<U,V>.dropTable()
        }
        
        leftModelContext.addLeftDependency(SingularRelationship<U,V>.self) { (id: Int64) -> Void in
            RelationshipReferenceTracker.setTemplate((U.self, V.self), template: relationship.template)
            var context = self.internalContextForModel(SingularRelationship<U,V>.self)
            let ids = idsForColumn(RelationshipColumns.LeftID, filterValue: id)
            for id in ids {
                context.localContextOfInstances.removeValueForKey(id)
            }
            self.setInternalContextForModel(SingularRelationship<U,V>.self, context: context)
        }
        self.setInternalContextForModel(modelType, context: leftModelContext)
        
        var rightModelContext = self.internalContextForModel(V.self)
        rightModelContext.addRightDependency(SingularRelationship<U,V>.self) { (id: Int64) -> Void in
            RelationshipReferenceTracker.setTemplate((U.self, V.self), template: relationship.template)
            var context = self.internalContextForModel(SingularRelationship<U,V>.self)
            let ids = idsForColumn(RelationshipColumns.RightID, filterValue: id)
            for id in ids {
                context.localContextOfInstances.removeValueForKey(id)
            }
            self.setInternalContextForModel(SingularRelationship<U,V>.self, context: context)
        }
        self.setInternalContextForModel(V.self, context: rightModelContext)
    }
    
    internal static func createRelationshipForModel<U: SQLiteModel, V: SQLiteModel>(modelType: U.Type, relationship: Relationship<[V]>) {
        
        RelationshipReferenceTracker.setTemplate((U.self, V.self), template: relationship.template)
        
        if relationship.unique {
            UniqueMultipleRelationship<U,V>.initialize()
            let _ = self.internalContextForModel(UniqueSingularRelationship<U,V>.self)
        }
        else {
            MultipleRelationship<U,V>.initialize()
            let _ = self.internalContextForModel(MultipleRelationship<U,V>.self)
        }
        
        func idsForColumn(column: Expression<Int64>, filterValue: Int64) -> [Int64] {
            RelationshipReferenceTracker.setTemplate((U.self, V.self), template: relationship.template)
            let context = self.internalContextForModel(MultipleRelationship<U,V>.self)
            let ids = context.localContextOfInstances.filter({ (keyVal : (Int64, SQLiteModelInstanceContext)) -> Bool in
                if let id = Meta.getValueForModel(MultipleRelationship<U,V>.self, hash: keyVal.0, expression: Expression<Int64?>(column)) {
                    return id == filterValue
                }
                return false
            }).map({ $0.0 })
            return ids
        }
        
        var leftModelContext = self.internalContextForModel(modelType)
        leftModelContext.addLeftModelDependency(MultipleRelationship<U,V>.self) {
            RelationshipReferenceTracker.setTemplate((U.self, V.self), template: relationship.template)
            let _ = try? MultipleRelationship<U,V>.dropTable()
        }
        
        leftModelContext.addLeftDependency(MultipleRelationship<U,V>.self) { (id: Int64) -> Void in
            RelationshipReferenceTracker.setTemplate((U.self, V.self), template: relationship.template)
            var context = self.internalContextForModel(MultipleRelationship<U,V>.self)
            let ids = idsForColumn(RelationshipColumns.LeftID, filterValue: id)
            for id in ids {
                context.localContextOfInstances.removeValueForKey(id)
            }
            self.setInternalContextForModel(MultipleRelationship<U,V>.self, context: context)
        }
        self.setInternalContextForModel(modelType, context: leftModelContext)
        
        var rightModelContext = self.internalContextForModel(V.self)
        rightModelContext.addRightDependency(MultipleRelationship<U,V>.self) { (id: Int64) -> Void in
            RelationshipReferenceTracker.setTemplate((U.self, V.self), template: relationship.template)
            var context = self.internalContextForModel(MultipleRelationship<U,V>.self)
            let ids = idsForColumn(RelationshipColumns.RightID, filterValue: id)
            for id in ids {
                context.localContextOfInstances.removeValueForKey(id)
            }
            self.setInternalContextForModel(MultipleRelationship<U,V>.self, context: context)
        }
        self.setInternalContextForModel(V.self, context: rightModelContext)
    }
    
    // MARK: Get
    
    internal static func getRelationshipForModel<U: SQLiteModel, V: SQLiteModel>(modelType: U.Type, hash: Int64, relationship: Relationship<V?>) -> V? {
        
        RelationshipReferenceTracker.setTemplate((U.self, V.self), template: relationship.template)
        
        let modelContext = self.internalContextForModel(modelType)
        guard modelContext.hasDependency(SingularRelationship<U,V>.self) else {
            fatalError("SQLiteModel Fatal Error: Dependency not set for relationship: \(relationship). Should never happen!")
        }
        if relationship.unique {
            return UniqueSingularRelationship<U,V>.getRelationship(hash)
        }
        else {
            return SingularRelationship<U,V>.getRelationship(hash)
        }
    }
    
    internal static func getRelationshipForModel<U: SQLiteModel, V: SQLiteModel>(modelType: U.Type, hash: Int64, relationship: Relationship<[V]>) -> [V] {
        
        RelationshipReferenceTracker.setTemplate((U.self, V.self), template: relationship.template)
        
        let modelContext = self.internalContextForModel(modelType)
        guard modelContext.hasDependency(SingularRelationship<U,V>.self) else {
            fatalError("SQLiteModel Fatal Error: Dependency not set for relationship: \(relationship). Should never happen!")
        }
        if relationship.unique {
            return UniqueMultipleRelationship<U,V>.getRelationship(hash)
        }
        else {
            return MultipleRelationship<U,V>.getRelationship(hash)
        }
    }
    
    // MARK: Set
    
    internal static func setRelationshipForModel<U: SQLiteModel, V: SQLiteModel>(modelType: U.Type, relationship: Relationship<V?>, value: (U,V?)) -> Bool {
        
        RelationshipReferenceTracker.setTemplate((U.self, V.self), template: relationship.template)
        
        let modelContext = self.internalContextForModel(modelType)
        guard modelContext.hasDependency(SingularRelationship<U,V>.self) else {
            fatalError("SQLiteModel Fatal Error: Dependency not set for relationship: \(relationship). Should never happen!")
        }
        if let rightValue = value.1 {
            if relationship.unique {
                UniqueSingularRelationship<U,V>.setRelationship(value.0, right: rightValue)
            }
            else {
                SingularRelationship<U,V>.setRelationship(value.0, right: rightValue)
            }
        }
        else {
            if relationship.unique {
                UniqueSingularRelationship<U,V>.removeLeft(value.0.localID)
            }
            else {
                SingularRelationship<U,V>.removeLeft(value.0.localID)
            }
        }
        
        return true
    }
    
    internal static func setRelationshipForModel<U: SQLiteModel, V: SQLiteModel>(modelType: U.Type, relationship: Relationship<[V]>, value: (U,[V])) -> Bool {
        
        RelationshipReferenceTracker.setTemplate((U.self, V.self), template: relationship.template)
        
        let modelContext = self.internalContextForModel(modelType)
        guard modelContext.hasDependency(SingularRelationship<U,V>.self) else {
            fatalError("SQLiteModel Fatal Error: Dependency not set for relationship: \(relationship). Should never happen!")
        }
        if value.1.count > 0 {
            if relationship.unique {
                UniqueMultipleRelationship<U,V>.setRelationship(value.0, right: value.1)
            }
            else {
                MultipleRelationship<U,V>.setRelationship(value.0, right: value.1)
            }
        }
        else {
            if relationship.unique {
                UniqueMultipleRelationship<U,V>.removeLeft(value.0.localID)
            }
            else {
                MultipleRelationship<U,V>.removeLeft(value.0.localID)
            }
        }
        
        return true
    }
}

// MARK: Context Models

internal struct SQLiteModelContext {
    
    internal typealias DeleteMappingOperation = () -> Void
    internal typealias DeleteInstanceOperation = (Int64) -> Void
    
    let table: Table
    let localIDExpression: Expression<Int64>
    let localCreatedAtExpression: Expression<NSDate>
    let localUpdatedAtExpression: Expression<NSDate>
    let tableName: String
    var localContextOfInstances: [Int64 : SQLiteModelInstanceContext]
    var leftModelDependencies: [String : DeleteMappingOperation]
    var leftDependencies: [String : DeleteInstanceOperation]
    var rightDependencies: [String : DeleteInstanceOperation]
    
    private struct Keys {
        static let localID = "sqlmdl_localID"
        static let localCreatedAt = "sqlmdl_localCreatedAt"
        static let localUpdatedAt = "sqlmdl_localUpdatedAt"
    }
    
    internal init(tableName: String) {
        self.tableName = tableName
        self.table = Table(self.tableName)
        self.localIDExpression = Expression<Int64>(Keys.localID)
        self.localCreatedAtExpression = Expression<NSDate>(Keys.localCreatedAt)
        self.localUpdatedAtExpression = Expression<NSDate>(Keys.localUpdatedAt)
        self.localContextOfInstances = [Int64 : SQLiteModelInstanceContext]()
        self.leftModelDependencies = [String : DeleteMappingOperation]()
        self.leftDependencies = [String : DeleteInstanceOperation]()
        self.rightDependencies = [String : DeleteInstanceOperation]()
    }
    
    internal mutating func createInstanceContextFromModel(row: Row) -> SQLiteModelInstanceContext {
        let instanceContext = SQLiteModelInstanceContext(row: row, context: self)
        let localID = row[self.localIDExpression]
        self.localContextOfInstances[localID] = instanceContext
        return instanceContext
    }
    
    internal mutating func deleteInstanceContextForHash(hash: Int64) {
        let _ = self.localContextOfInstances.removeValueForKey(hash)
        self.deleteLeftDependencies(hash)
        self.deleteRightDependencies(hash)
    }
    
    internal mutating func addLeftModelDependency<V: SQLiteModel>(ofType: V.Type,  deleteOperation: DeleteMappingOperation) {
        LogManager.log("Adding Left Model Dependency: \(V.tableName)")
        self.leftModelDependencies[V.tableName] = deleteOperation
    }
    
    internal mutating func addLeftDependency<V: SQLiteModel>(ofType: V.Type,  deleteOperation: DeleteInstanceOperation) {
        LogManager.log("Adding Left Dependency: \(V.tableName)")
        self.leftDependencies[V.tableName] = deleteOperation
    }
    
    internal mutating func addRightDependency<V: SQLiteModel>(ofType: V.Type,  deleteOperation: DeleteInstanceOperation) {
        LogManager.log("Adding Right Dependency: \(V.tableName)")
        self.rightDependencies[V.tableName] = deleteOperation
    }
    
    internal func hasLeftDependency<V: SQLiteModel>(ofType: V.Type) -> Bool {
        return self.leftDependencies[V.tableName] != nil
    }
    
    internal func hasRightDependency<V: SQLiteModel>(ofType: V.Type) -> Bool {
        return self.rightDependencies[V.tableName] != nil
    }
    
    internal func hasDependency<V: SQLiteModel>(ofType: V.Type) -> Bool {
        return self.hasLeftDependency(ofType) || self.hasRightDependency(ofType)
    }
    
    internal func deleteLeftModelDependencies() {
        for deleteOperation in self.leftModelDependencies.values {
            deleteOperation()
        }
    }
    
    internal func deleteLeftDependencies(forID: Int64) {
        for deleteOperation in self.leftDependencies.values {
            deleteOperation(forID)
        }
    }
    
    internal func deleteRightDependencies(forID: Int64) {
        for deleteOperation in self.rightDependencies.values {
            deleteOperation(forID)
        }
    }
}

internal struct ValueWrapper {
    let value: Any?
}

internal struct SQLiteModelInstanceContext {
    
    var localCreatedAt: NSDate!
    var localUpdatedAt: NSDate!
    var row: Row!
    private  var columnValueMapping: [String : ValueWrapper]
    private(set) var setters: [Setter]
    
    internal init(row: Row, context: SQLiteModelContext) {
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
