//
//  SQLiteModelImplementation.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 4/2/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import Foundation
import SQLite

// MARK: Variable Implementation

public extension SQLiteModel {
    
    static var tableName : String {
        return String(self)
    }
    
    static var connection: Database? {
        return try? Database.sharedDatabase()
    }
    
    internal static var contextManager: SQLiteModelContextManager {
        guard let contextManager = self.connection?.cache else {
            fatalError("SQLiteModel Fatal Error: Database connection is nil")
        }
        return contextManager
    }
    
    internal var contextManager: SQLiteModelContextManager {
        return self.dynamicType.contextManager
    }
    
    internal static var table : Table {
        return contextManager.tableForModel(self)
    }
    
    internal static var localIDExpression : Expression<SQLiteModelID> {
        return contextManager.localIDExpressionForModel(self)
    }
    
    internal static var localUpdatedAtExpression : Expression<NSDate> {
        return contextManager.localUpdatedAtExpressionForModel(self)
    }
    
    internal static var localCreatedAtExpression : Expression<NSDate> {
        return contextManager.localCreatedAtExpressionForModel(self)
    }
    
    internal static func instanceQueryWithLocalID(localID: SQLiteModelID) -> QueryType {
        let instance = self.table.filter(self.localIDExpression == localID)
        return instance
    }
    
    internal var instanceQuery: QueryType {
        return self.dynamicType.instanceQueryWithLocalID(localID)
    }
    
    var localCreatedAt: NSDate? {
        return contextManager.localCreatedAtForModel(self.dynamicType, hash: self.localID)
    }
    
    var localUpdatedAt: NSDate? {
        return contextManager.localUpdatedAtForModel(self.dynamicType, hash: self.localID)
    }
    
    static var query: QueryType {
        return self.table.select(*)
    }
}

// MARK: Method Implementation

public extension SQLiteModel {
    
    // MARK: Connections
    
    internal typealias ConnectionBlock = (connection: Connection) throws -> Void
    internal static func sqlmdl_connect(error error: SQLiteModelError, instance: Any? = nil, connectionBlock: ConnectionBlock) throws -> Void {
        do {
            guard let connection = self.connection else {
                throw error
            }
            try connectionBlock(connection: connection.connection())
        }
        catch let caughtError {
            error.logError(self, error: caughtError)
            throw error
        }
    }
    
    internal typealias ConnectionFetchBlock = (connection: Connection) throws -> [Self]
    internal static func sqlmdl_connect(error error: SQLiteModelError, connectionBlock: ConnectionFetchBlock) throws -> [Self] {
        do {
            guard let connection = self.connection else {
                throw error
            }
            let result = try connectionBlock(connection: connection.connection())
            return result
        }
        catch let caughtError {
            error.logError(self, error: caughtError)
            throw error
        }
    }
    
    internal static func sqlmdl_connect<V: Value>(error error: SQLiteModelError = .ScalarQueryError, connectionBlock: (connection: Connection) throws -> V?) throws -> V? {
        do {
            guard let connection = self.connection else {
                throw error
            }
            let result = try connectionBlock(connection: connection.connection())
            return result
        }
        catch let caughtError {
            error.logError(self, error: caughtError)
            throw error
        }
    }
    
    internal func connect(error error: SQLiteModelError, connectionBlock: ConnectionBlock) throws -> Void {
        try self.dynamicType.sqlmdl_connect(error: error, instance: self, connectionBlock: connectionBlock)
    }
    
    internal static func connect(error error: SQLiteModelError, connectionBlock: ConnectionBlock) throws -> Void {
        try self.sqlmdl_connect(error: error, connectionBlock: connectionBlock)
    }
    
    internal static func connectForFetch(error error: SQLiteModelError, connectionBlock: ConnectionFetchBlock) throws -> [Self] {
        let result = try self.sqlmdl_connect(error: error, connectionBlock: connectionBlock)
        return result
    }
    
    internal static func connectForScalarQuery<V: Value>(connectionBlock: (connection: Connection) throws -> V?) throws -> V? {
        let result = try self.sqlmdl_connect(connectionBlock:connectionBlock)
        return result
    }
    
    // MARK: SQLiteTableOperations
    
    final static func createTable() throws -> Void {
        
        try self.connect(error: SQLiteModelError.CreateError, connectionBlock: { connection in
            let statement: String = self.table.create(temporary: false, ifNotExists: true, block: { tableBuilder in
                tableBuilder.column(self.localIDExpression, primaryKey: .Autoincrement)
                tableBuilder.column(self.localCreatedAtExpression)
                tableBuilder.column(self.localUpdatedAtExpression)
                self.buildTable(tableBuilder)
            })
            try connection.run(statement)
            let schemaUpdater = SchemaUpdater(table: self.table, tableName: self.tableName)
            self.alterSchema(schemaUpdater)
            for alteration in schemaUpdater.alterations {
                try connection.run(alteration)
            }
            schemaUpdater.markAlterationsComplete()
        })
    }
    
    static func createTableInBackground(completion: Completion? = nil) {
        SyncManager.async(self, execute: {
            try self.createTable()
            SyncManager.main(completion, error: nil)
        }) {
            SyncManager.main(completion, error: .CreateError)
        }
    }
    
    final static func createIndex(columns: [Expressible], unique: Bool = false) throws -> Void {
        guard columns.count > 0 else {
            throw SQLiteModelError.CreateError
        }
        try self.connect(error: SQLiteModelError.IndexError, connectionBlock: { connection in
            let statement = self.table.createIndex(columns, unique: unique, ifNotExists: true)
            try connection.run(statement)
        })
    }
    
    static func createIndexInBackground(columns: [Expressible], unique: Bool = false, completion: Completion? = nil) {
        SyncManager.async(self, execute: {
            try self.createIndex(columns, unique: unique)
            SyncManager.main(completion, error: nil)
        }) {
            SyncManager.main(completion, error: .IndexError)
        }
    }
    
    final static func dropTable() throws -> Void {
        
        try self.connect(error: SQLiteModelError.DropError, connectionBlock: { connection in
            try connection.run(self.table.drop(ifExists: true))
            contextManager.removeContextForModel(self)
            let schemaUpdater = SchemaUpdater(table: self.table, tableName: self.tableName)
            self.alterSchema(schemaUpdater)
            schemaUpdater.invalidateAlterations()
        })
    }
    
    static func dropTableInBackground(completion: Completion? = nil) {
        SyncManager.async(self, execute: {
            try self.dropTable()
            SyncManager.main(completion, error: nil)
        }) {
            SyncManager.main(completion, error: .DropError)
        }
    }
    
    // MARK: SQLiteDeletable
    
    final static func deleteAll() throws -> Void {
        try self.delete(self.query)
        contextManager.removeAllLocalInstanceContextsFor(self)
    }
    
    static func deleteAllInBackground(completion: Completion? = nil) -> Void {
        self.deleteInBackground(self.query)
    }
    
    final static func delete(query: QueryType) throws -> Void {
        
        try self.connect(error: SQLiteModelError.DeleteError, connectionBlock: { connection in
            for row in try connection.prepare(query) {
                let ID = row[self.localIDExpression]
                contextManager.removeLocalInstanceContextFor(self, hash: ID)
            }
            try connection.run(query.delete())
        })
    }
    
    final static func deleteInBackground(query: QueryType, completion: Completion? = nil) -> Void {
        SyncManager.async(self, execute: {
            try self.delete(query)
            SyncManager.main(completion, error: nil)
        }) {
            SyncManager.main(completion, error: .DeleteError)
        }
    }
    
    // MARK: SQLiteCreatable
    
    final static func new(setters: [Setter], relationshipSetters: [RelationshipSetter] = []) throws -> Self {
        let result = try self.connectForFetch(error: SQLiteModelError.InsertError, connectionBlock: { connection in
            let now = NSDate()
            var setters = setters
            setters.append(self.localCreatedAtExpression <- now)
            setters.append(self.localUpdatedAtExpression <- now)
            let rowID = try connection.run(self.table.insert(or: OnConflict.Replace, setters))
            guard let row = connection.pluck(self.table.select(distinct: *).filter(rowid == rowID)) else {
                throw SQLiteModelError.InsertError
            }
            let localID = row[self.localIDExpression]
            let instance = Self(localID: localID)
            contextManager.createLocalInstanceContextFor(self, row: row)
            for relationshipSetter in relationshipSetters {
                relationshipSetter.action(instance)
            }
            return [instance]
        })
        return result.first!
    }
    
    final static func newInBackground(setters: [Setter], relationshipSetters: [RelationshipSetter] = [], completion: ((Self?, SQLiteModelError?) -> Void)? = nil) {
        SyncManager.async(self, execute: {
            let instance = try self.new(setters, relationshipSetters: relationshipSetters)
            if let completion = completion {
                SyncManager.main({
                    completion(instance, nil)
                })
            }
        }) {
            if let completion = completion {
                SyncManager.main({
                    completion(nil, SQLiteModelError.InsertError)
                })
            }
        }
    }
    
    // MARK: SQLiteFetchable
    
    final static func find(id: SQLiteModelID) throws -> Self {
        if contextManager.hasLocalInstanceContextFor(self, hash: id) {
            return Self(localID: id)
        }
        
        let result = try self.connectForFetch(error: SQLiteModelError.FetchError, connectionBlock: { connection in
            guard let row = connection.pluck(self.query.filter(self.localIDExpression == id)) else {
                throw SQLiteModelError.FetchError
            }
            let localID = row[self.localIDExpression]
            if let _ = contextManager.localInstanceContextForModel(self, hash: localID) {} else {
                contextManager.createLocalInstanceContextFor(self, row: row)
            }
            let instance = Self(localID: localID)
            return [instance]
        })
        guard result.count == 1 else {
            throw SQLiteModelError.FetchError
        }
        return result[0]
    }
    
    final static func findInBackground(id: SQLiteModelID, completion: (Self?, SQLiteModelError?) -> Void) {
        SyncManager.async(self, execute: {
            let instance = try self.find(id)
            completion(instance, nil)
        }) {
            completion(nil, SQLiteModelError.FetchError)
        }
    }
    
    final static func fetchAll() throws -> [Self] {
        let result = try self.fetch(self.query)
        return result
    }
    
    final static func fetchAllInBackground(completion: ([Self], SQLiteModelError?) -> Void) {
        self.fetchInBackground(self.query, completion: completion)
    }
    
    final static func fetch(query: QueryType) throws -> [Self] {
        let result = try self.connectForFetch(error: SQLiteModelError.FetchError, connectionBlock: { connection in
            var fetchedInstances: [Self] = []
            for row in try connection.prepare(query) {
                let localID = row[self.localIDExpression]
                contextManager.createLocalInstanceContextFor(self, row: row)
                let instance = Self(localID: localID)
                fetchedInstances.append(instance)
            }
            return fetchedInstances
        })
        return result
    }
    
    final static func fetchInBackground(query: QueryType, completion: ([Self], SQLiteModelError?) -> Void) {
        SyncManager.async(self, execute: {
            let instances = try self.fetch(query)
            SyncManager.main({
                completion(instances, nil)
            })
        }) {
            SyncManager.main({
                completion([], SQLiteModelError.FetchError)
            })
        }
    }
    
    // MARK: SQLiteUpdatable
    
    private static func sqlmdl_update(query: QueryType, setters: [Setter], relationshipSetters: [RelationshipSetter]) throws -> Void {
        try self.connect(error: SQLiteModelError.UpdateError, connectionBlock: { connection in

            let now = NSDate()
            let updatedSetters = [self.localUpdatedAtExpression <- now] + setters
            try connection.run(query.update(updatedSetters))
            
            if relationshipSetters.count > 0 {
                let instances = try self.fetch(query)
                for instance in instances {
                    for relationshipSetter in relationshipSetters {
                        relationshipSetter.action(instance)
                    }
                }
            }
            for row in try connection.prepare(query) {
                contextManager.createLocalInstanceContextFor(self, row: row)
            }
        })
    }
    
    final static func update(query: QueryType, setters: [Setter] = [], relationshipSetters: [RelationshipSetter] = []) throws -> Void {
        try self.sqlmdl_update(query, setters: setters, relationshipSetters: relationshipSetters)
    }
    
    final static func updateInBackground(query: QueryType, setters: [Setter] = [], relationshipSetters: [RelationshipSetter] = [], completion: Completion?) {
        SyncManager.async(self, execute: {
            try self.update(query, setters: setters, relationshipSetters: relationshipSetters)
            SyncManager.main(completion, error: nil)
        }) {
            SyncManager.main(completion, error: .UpdateError)
        }
    }
    
    final static func updateAll(setters: [Setter] = [], relationshipSetters: [RelationshipSetter] = []) throws -> Void {
        try self.sqlmdl_update(self.query, setters: setters, relationshipSetters: relationshipSetters)
    }
    
    final static func updateAllInBackground(setters: [Setter] = [], relationshipSetters: [RelationshipSetter] = [], completion: Completion? = nil) {
        self.updateInBackground(query, setters: setters, relationshipSetters: relationshipSetters, completion: completion)
    }
    
    // MARK: SQLiteInstance
    
    init(localID: SQLiteModelID = -1) {
        self.init()
        self.localID = localID
    }
    
    final mutating func save() throws {
        try self.connect(error: SQLiteModelError.UpdateError, connectionBlock: { (connection) -> Void in
            let now = NSDate()
            var setters = self.contextManager.settersForModel(self.dynamicType, hash: self.localID)
            setters.append(self.dynamicType.localUpdatedAtExpression <- now)
            try connection.run(self.instanceQuery.update(setters))
            guard let row = connection.pluck(self.dynamicType.table.select(distinct: *).filter(self.dynamicType.localIDExpression == self.localID)) else {
                throw SQLiteModelError.UpdateError
            }
            self.contextManager.createLocalInstanceContextFor(self.dynamicType, row: row)
        })
    }
    
    final mutating func saveInBackground(completion: Completion? = nil) {
        SyncManager.async(self.dynamicType, execute: {
            try self.save()
            SyncManager.main(completion, error: nil)
        }) {
            SyncManager.main(completion, error: .UpdateError)
        }
    }
    
    final func delete() throws {
        try self.connect(error: SQLiteModelError.DeleteError, connectionBlock: { (connection) -> Void in
            try connection.run(self.instanceQuery.delete())
            self.contextManager.removeLocalInstanceContextFor(self.dynamicType, hash: self.localID)
        })
    }
    
    final func deleteInBackground(completion: Completion? = nil) {
        SyncManager.async(self.dynamicType, execute: {
            try self.delete()
            SyncManager.main(completion, error: nil)
        }) {
            SyncManager.main(completion, error: .DeleteError)
        }
    }
    
    func countForRelationship<V: SQLiteModel>(column: Relationship<[V]>) -> Int {
        return contextManager.countForRelationshipForInstance(self, relationship: column)
    }
    
    // MARK: SQLiteModelAbstract
    
    static func alterSchema(schemaUpdater: SchemaUpdater) -> Void {
        // Empty implimentation to make method optional
    }
    
    // MARK: SQLiteConvertible
    
    // Set
    
    final func get<V: Value>(column: Expression<V>) -> V {
        return self.get(Expression<V?>(column))!
    }
    
    final func get<V: SQLite.Value>(column: Expression<V?>) -> V? {
        let value = contextManager.getValueForModel(self.dynamicType, hash: self.localID, expression: column)
        return value
    }
    
    final func get<V: SQLiteModel>(column: Relationship<V>) -> V {
        return self.get(Relationship<V?>(column))!
    }
    
    final func get<V: SQLiteModel>(column: Relationship<V?>) -> V? {
        return contextManager.getRelationshipForModel(self.dynamicType, hash: self.localID, relationship: column)
    }
    
    final func get<V: SQLiteModel>(column: Relationship<[V]>) -> [V] {
        return contextManager.getRelationshipForModel(self.dynamicType, hash: self.localID, relationship: column)
    }
    
    final func getInBackground<V: SQLiteModel>(column: Relationship<V>, completion: (V) -> Void) {
        SyncManager.async(self.dynamicType) {
            let value = self.get(column)
            SyncManager.main({
                completion(value)
            })
        }
    }
    
    final func getInBackground<V: SQLiteModel>(column: Relationship<V?>, completion: (V?) -> Void) {
        SyncManager.async(self.dynamicType) {
            let value = self.get(column)
            SyncManager.main({
                completion(value)
            })
        }
    }
    
    final func getInBackground<V: SQLiteModel>(column: Relationship<[V]>, completion: ([V]) -> Void) {
        SyncManager.async(self.dynamicType) {
            let value = self.get(column)
            SyncManager.main({
                completion(value)
            })
        }
    }
    
    // Set
    
    final func set<V: Value>(column: Expression<V>, value: V) {
        self.set(Expression<V?>(column), value: value)
    }
    
    final func set<V: Value>(column: Expression<V?>, value: V?) {
        contextManager.setValueForModel(self.dynamicType, hash: self.localID, column: column, value: value)
    }
    
    final func set<V: SQLiteModel>(column: Relationship<V>, value: V) {
        self.set(Relationship<V?>(column), value: value)
    }
    
    final func set<V: SQLiteModel>(column: Relationship<V?>, value: V?) {
        contextManager.setRelationshipForModel(self.dynamicType, relationship: column, value: (self, value))
    }
    
    final func set<V: SQLiteModel>(column: Relationship<[V]>, value: [V]) {
        contextManager.setRelationshipForModel(self.dynamicType, relationship: column, value: (self, value))
    }
    
    final func setInBackground<V: SQLiteModel>(column: Relationship<V>, value: V, completion: (Void -> Void)? = nil) {
        SyncManager.async(self.dynamicType) {
            self.set(column, value: value)
            if let completion = completion {
                SyncManager.main(completion)
            }
        }
    }
    
    final func setInBackground<V: SQLiteModel>(column: Relationship<V?>, value: V?, completion: (Void -> Void)? = nil) {
        SyncManager.async(self.dynamicType) {
            self.set(column, value: value)
            if let completion = completion {
                SyncManager.main(completion)
            }
        }
    }
    
    final func setInBackground<V: SQLiteModel>(column: Relationship<[V]>, value: [V], completion: (Void -> Void)? = nil) {
        SyncManager.async(self.dynamicType) {
            self.set(column, value: value)
            if let completion = completion {
                SyncManager.main(completion)
            }
        }
    }
    
    // MARK: SQLiteScalarQueryable
    
    static func count() throws -> Int {
        return try self.connectForScalarQuery({ connection in
            return connection.scalar(self.table.count)
        })!
    }
    
    static func countInBackground(completion: (Int, SQLiteModelError?) -> Void) {
        SyncManager.async(self, execute: {
            let count = try self.count()
            SyncManager.main({
                completion(count, nil)
            })
        }, onError: {
            SyncManager.main({
                completion(0, SQLiteModelError.ScalarQueryError)
            })
        })
    }
    
    // MARK: SQLiteAtomic
    
    static func transaction(execute: Void -> Void) {
        SyncManager.lock(self, block: execute)
    }
}
