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
    
    internal static func localIDExpressionForModel<V: SQLiteModel>(modelType: V.Type) -> Expression<SQLiteModelID> {
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
    
    internal static func localInstanceContextForModel<V: SQLiteModel>(modelType: V.Type, hash: SQLiteModelID) -> SQLiteModelInstanceContext? {
        var context = self.sharedInstance.internalContextForModel(modelType)
        guard let instanceContext = context.localContextOfInstances[hash] else {
            return nil
        }
        return instanceContext
    }
    
    internal static func getValueForModel<U: SQLiteModel, V: Value>(modelType: U.Type, hash: SQLiteModelID, expression: Expression<V?>) -> V? {
        guard let instanceContext = self.localInstanceContextForModel(modelType, hash: hash) else {
            return nil
        }
        return instanceContext.get(expression)
    }
    
    internal static func setValueForModel<U: SQLiteModel, V: Value>(modelType: U.Type, hash: SQLiteModelID, column: Expression<V?>, value: V?) {
        guard var instanceContext = self.localInstanceContextForModel(modelType, hash: hash) else {
            return
        }
        instanceContext[column.template] = ValueWrapper(value: value)
        instanceContext.setters.append(column <- value as Setter)
        var context = self.internalContextForModel(modelType)
        context.localContextOfInstances[hash] = instanceContext
        self.setInternalContextForModel(modelType, context: context)
    }
    
    internal static func localCreatedAtForModel<V: SQLiteModel>(modelType: V.Type, hash: SQLiteModelID) -> NSDate? {
        guard let instanceContext = self.localInstanceContextForModel(modelType, hash: hash) else {
            return nil
        }
        return instanceContext.localCreatedAt
    }
    
    internal static func localUpdatedAtForModel<V: SQLiteModel>(modelType: V.Type, hash: SQLiteModelID) -> NSDate? {
        guard let instanceContext = self.localInstanceContextForModel(modelType, hash: hash) else {
            return nil
        }
        return instanceContext.localUpdatedAt
    }
    
    internal static func settersForModel<V: SQLiteModel>(modelType: V.Type, hash: SQLiteModelID) -> [Setter] {
        guard let instanceContext = self.localInstanceContextForModel(modelType, hash: hash) else {
            return []
        }
        return instanceContext.setters
    }
    
    internal static func hasLocalInstanceContextFor<V: SQLiteModel>(modelType: V.Type, hash: SQLiteModelID) -> Bool {
        let context = self.internalContextForModel(modelType)
        let instanceContext = context.localContextOfInstances[hash]
        return instanceContext != nil
    }
    
    internal static func hasLocalInstanceContextForSingularRelationhip<V: SQLiteModel>(modelType: V.Type, leftID: SQLiteModelID) -> Bool {
        let context = self.internalContextForModel(modelType)
        let instanceContexts = context.localContextOfInstances.values.filter({ $0.get(RelationshipColumns.LeftID) == leftID })
        assert(instanceContexts.count <= 1)
        return instanceContexts.count > 0
    }
    
    // return value: left = ids that are cached, right = ids that arent cached
    internal static func queryCachedInstanceIDsFor<V: SQLiteModel>(modelType: V.Type, hashes: [SQLiteModelID]) -> ([SQLiteModelID], [SQLiteModelID]) {
        let context = self.internalContextForModel(modelType)
        var left: [SQLiteModelID] = [], right: [SQLiteModelID] = []
        for hash in hashes {
            if let _ = context.localContextOfInstances[hash] {
                left.append(hash)
            }
            else {
                right.append(hash)
            }
        }
        return (left, right)
    }
    
    internal static func queryCachedValueForSingularRelationship<V: RelationshipModel>(modelType: V.Type, queryColumn: Expression<SQLiteModelID>, queryValue: SQLiteModelID, returnColumn: Expression<SQLiteModelID>) -> SQLiteModelID? {
        let context = self.internalContextForModel(modelType)
        for instanceContext in context.localContextOfInstances.values {
            if instanceContext.get(queryColumn) == queryValue {
                return instanceContext.get(returnColumn)
            }
        }
        return nil
    }
    
    internal static func queryCachedValueForRelationship<V: RelationshipModel>(modelType: V.Type, queryColumn: Expression<SQLiteModelID>, queryValue: SQLiteModelID, returnColumn: Expression<SQLiteModelID>) -> [SQLiteModelID] {
        let context = self.internalContextForModel(modelType)
        let instances = context.localContextOfInstances.values.filter{ $0.get(queryColumn) == queryValue }
        return instances.map{ $0.get(returnColumn) }
    }
    
    internal static func createLocalInstanceContextFor<V: SQLiteModel>(modelType: V.Type, row: Row) {
        var context = self.internalContextForModel(modelType)
        let _ = context.createInstanceContextFromModel(row)
        self.setInternalContextForModel(modelType, context: context)
    }
    
    internal static func removeLocalInstanceContextFor<V: SQLiteModel>(modelType: V.Type, hash: SQLiteModelID) {
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
    
    // MARK: Count
    
    internal static func countForRelationshipForInstance<U: SQLiteModel, V: SQLiteModel>(model: U, relationship: Relationship<[V]>) -> Int {
        let count = self.queryCachedValueForRelationship(MultipleRelationship<U,V>.self, queryColumn: RelationshipColumns.LeftID, queryValue: model.localID, returnColumn: RelationshipColumns.RightID).count
        return count
    }
    
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
        
        func idsForColumn(column: Expression<SQLiteModelID>, filterValue: SQLiteModelID) -> [SQLiteModelID] {
            RelationshipReferenceTracker.setTemplate((U.self, V.self), template: relationship.template)
            let context = self.internalContextForModel(SingularRelationship<U,V>.self)
            let ids = context.localContextOfInstances.filter({ (keyVal : (SQLiteModelID, SQLiteModelInstanceContext)) -> Bool in
                if let id = Meta.getValueForModel(SingularRelationship<U,V>.self, hash: keyVal.0, expression: Expression<SQLiteModelID?>(column)) {
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
        
        leftModelContext.addLeftDependency(SingularRelationship<U,V>.self) { (id: SQLiteModelID) -> Void in
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
        rightModelContext.addRightDependency(SingularRelationship<U,V>.self) { (id: SQLiteModelID) -> Void in
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
        
        func idsForColumn(column: Expression<SQLiteModelID>, filterValue: SQLiteModelID) -> [SQLiteModelID] {
            RelationshipReferenceTracker.setTemplate((U.self, V.self), template: relationship.template)
            let context = self.internalContextForModel(MultipleRelationship<U,V>.self)
            let ids = context.localContextOfInstances.filter({ (keyVal : (SQLiteModelID, SQLiteModelInstanceContext)) -> Bool in
                if let id = Meta.getValueForModel(MultipleRelationship<U,V>.self, hash: keyVal.0, expression: Expression<SQLiteModelID?>(column)) {
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
        
        leftModelContext.addLeftDependency(MultipleRelationship<U,V>.self) { (id: SQLiteModelID) -> Void in
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
        rightModelContext.addRightDependency(MultipleRelationship<U,V>.self) { (id: SQLiteModelID) -> Void in
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
    
    internal static func getRelationshipForModel<U: SQLiteModel, V: SQLiteModel>(modelType: U.Type, hash: SQLiteModelID, relationship: Relationship<V?>) -> V? {
        
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
    
    internal static func getRelationshipForModel<U: SQLiteModel, V: SQLiteModel>(modelType: U.Type, hash: SQLiteModelID, relationship: Relationship<[V]>) -> [V] {
        
        RelationshipReferenceTracker.setTemplate((U.self, V.self), template: relationship.template)
        
        let modelContext = self.internalContextForModel(modelType)
        guard modelContext.hasDependency(MultipleRelationship<U,V>.self) else {
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
    
    internal static func setRelationshipForModel<U: SQLiteModel, V: SQLiteModel>(modelType: U.Type, relationship: Relationship<V?>, value: (U,V?)) {
        
        RelationshipReferenceTracker.setTemplate((U.self, V.self), template: relationship.template)
        
        let modelContext = self.internalContextForModel(modelType)
        guard modelContext.hasDependency(SingularRelationship<U,V>.self) else {
            fatalError("SQLiteModel Fatal Error: Dependency not set for relationship: \(relationship). Should never happen!")
        }
        if let rightValue = value.1 {
            if relationship.unique {
                if let hash = self.queryCachedValueForSingularRelationship(UniqueSingularRelationship<U,V>.self, queryColumn: RelationshipColumns.RightID, queryValue: rightValue.localID, returnColumn: UniqueSingularRelationship<U,V>.localIDExpression) {
                    var relationshipContext = self.internalContextForModel(UniqueSingularRelationship<U,V>.self)
                    relationshipContext.localContextOfInstances.removeValueForKey(hash)
                    self.setInternalContextForModel(UniqueSingularRelationship<U,V>.self, context: relationshipContext)
                }
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
    }
    
    internal static func setRelationshipForModel<U: SQLiteModel, V: SQLiteModel>(modelType: U.Type, relationship: Relationship<[V]>, value: (U,[V])) {
        
        RelationshipReferenceTracker.setTemplate((U.self, V.self), template: relationship.template)
        
        let modelContext = self.internalContextForModel(modelType)
        guard modelContext.hasDependency(MultipleRelationship<U,V>.self) else {
            fatalError("SQLiteModel Fatal Error: Dependency not set for relationship: \(relationship). Should never happen!")
        }
        if value.1.count > 0 {
            if relationship.unique {
                
                var relationshipContext = self.internalContextForModel(UniqueMultipleRelationship<U,V>.self)
                for rightModel in value.1 {
                    let hashesForModel = self.queryCachedValueForRelationship(UniqueMultipleRelationship<U,V>.self, queryColumn: RelationshipColumns.RightID, queryValue: rightModel.localID, returnColumn: UniqueMultipleRelationship<U,V>.localIDExpression)
                    for hash in hashesForModel {
                        relationshipContext.localContextOfInstances.removeValueForKey(hash)
                    }
                }
                self.setInternalContextForModel(UniqueSingularRelationship<U,V>.self, context: relationshipContext)
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
    }
}

// MARK: Context Models

internal struct SQLiteModelContext {
    
    internal typealias DeleteMappingOperation = () -> Void
    internal typealias DeleteInstanceOperation = (SQLiteModelID) -> Void
    
    let table: Table
    let localIDExpression: Expression<SQLiteModelID>
    let localCreatedAtExpression: Expression<NSDate>
    let localUpdatedAtExpression: Expression<NSDate>
    let tableName: String
    var localContextOfInstances: [SQLiteModelID : SQLiteModelInstanceContext]
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
        self.localIDExpression = Expression<SQLiteModelID>(Keys.localID)
        self.localCreatedAtExpression = Expression<NSDate>(Keys.localCreatedAt)
        self.localUpdatedAtExpression = Expression<NSDate>(Keys.localUpdatedAt)
        self.localContextOfInstances = [SQLiteModelID : SQLiteModelInstanceContext]()
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
    
    internal mutating func deleteInstanceContextForHash(hash: SQLiteModelID) {
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
    
    internal func deleteLeftDependencies(forID: SQLiteModelID) {
        for deleteOperation in self.leftDependencies.values {
            deleteOperation(forID)
        }
    }
    
    internal func deleteRightDependencies(forID: SQLiteModelID) {
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
    
    internal func get<V: Value>(expression: Expression<V>) -> V {
        if let wrappedValue = self[expression.template] {
            return wrappedValue.value as! V
        }
        return self.row.get(expression)
    }
    
    internal func get<V: Value>(expression: Expression<V?>) -> V? {
        if let wrappedValue = self[expression.template] {
            return wrappedValue.value as? V
        }
        return self.row.get(expression)
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
