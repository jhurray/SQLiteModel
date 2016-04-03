//
//  SQLiteModelImplementation.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 4/2/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import Foundation
import SQLite

// MARK: Internal Implementation

internal extension SQLiteModel {
    
    internal static var tableName : String {
        return String(self)
    }
    
    internal static var table : Table {
        return Meta.tableForModel(self)
    }
    
    internal static var localIDExpression : Expression<Int64> {
        return Meta.localIDExpressionForModel(self)
    }
    
    internal static var localUpdatedAtExpression : Expression<NSDate> {
        return Meta.localUpdatedAtExpressionForModel(self)
    }
    
    internal static var localCreatedAtExpression : Expression<NSDate> {
        return Meta.localCreatedAtExpressionForModel(self)
    }
    
    internal static func instanceQueryWithLocalID(localID: Int64) -> QueryType {
        let instance = self.table.filter(self.localIDExpression == localID)
        return instance
    }
    
    internal var instanceQuery: QueryType {
        return self.dynamicType.instanceQueryWithLocalID(localID)
    }
    
    var localCreatedAt: NSDate? {
        return Meta.localCreatedAtForModel(self.dynamicType, hash: self.localID)
    }
    
    var localUpdatedAt: NSDate? {
        return Meta.localUpdatedAtForModel(self.dynamicType, hash: self.localID)
    }
    
    static var query: QueryType {
        return self.table.select(*)
    }
}

// MARK: Implementation

public extension SQLiteModel {
    
    private typealias ConnectionBlock = (connection: Connection) throws -> Void
    private static func sqlmdl_connect(error error: SQLiteModelError, instance: Any? = nil, connectionBlock: ConnectionBlock) throws -> Void {
        do {
            let connection = try SQLiteDatabaseManager.connection()
            try connectionBlock(connection: connection)
        }
        catch let caughtError {
            error.logError(self, error: caughtError)
            throw error
        }
    }
    
    private typealias ConnectionFetchBlock = (connection: Connection) throws -> [Self]
    private static func sqlmdl_connect(error error: SQLiteModelError, connectionBlock: ConnectionFetchBlock) throws -> [Self] {
        do {
            let connection = try SQLiteDatabaseManager.connection()
            let result = try connectionBlock(connection: connection)
            return result
        }
        catch let caughtError {
            error.logError(self, error: caughtError)
            throw error
        }
    }
    
    private static func connect(error error: SQLiteModelError, connectionBlock: ConnectionBlock) throws -> Void {
        try self.sqlmdl_connect(error: error, connectionBlock: connectionBlock)
    }
    
    private static func connectForFetch(error error: SQLiteModelError, connectionBlock: ConnectionFetchBlock) throws -> [Self] {
        let result = try self.sqlmdl_connect(error: error, connectionBlock: connectionBlock)
        return result
    }
    
    private func connect(error error: SQLiteModelError, connectionBlock: ConnectionBlock) throws -> Void {
        try self.dynamicType.sqlmdl_connect(error: error, instance: self, connectionBlock: connectionBlock)
    }
    
    final static func createTable() throws -> Void {
        
        try self.connect(error: SQLiteModelError.CreateError, connectionBlock: { connection in
            let statement: String = self.table.create(temporary: false, ifNotExists: true, block: { tableBuilder in
                tableBuilder.column(self.localIDExpression, primaryKey: .Autoincrement)
                tableBuilder.column(self.localCreatedAtExpression)
                tableBuilder.column(self.localUpdatedAtExpression)
                self.buildTable(tableBuilder)
            })
            
            try connection.run(statement)
        })
    }
    
    final internal static func createIndex(columns: [Expressible], unique: Bool = false) throws -> Void {
        try self.connect(error: SQLiteModelError.IndexError, connectionBlock: { connection in
            let statement = self.table.createIndex(columns, unique: unique, ifNotExists: true)
            try connection.run(statement)
        })
    }
    
    final static func dropTable() throws -> Void {
        
        try self.connect(error: SQLiteModelError.DropError, connectionBlock: { connection in
            try connection.run(self.table.drop(ifExists: true))
            Meta.removeContextForModel(self)
        })
    }
    
    final static func deleteAll() throws -> Void {
        try self.delete(self.query)
        Meta.removeAllLocalInstanceContextsFor(self)
    }
    
    static func delete(query: QueryType) throws -> Void {
        
        try self.connect(error: SQLiteModelError.DeleteError, connectionBlock: { connection in
            let rows = try connection.prepare(query)
            try connection.run(query.delete())
            for row in rows {
                let ID = row[self.localIDExpression]
                Meta.removeLocalInstanceContextFor(self, hash: ID)
            }
        })
    }
    
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
            Meta.createLocalInstanceContextFor(self, row: row)
            for relationshipSetter in relationshipSetters {
                relationshipSetter.action(instance)
            }
            return [instance]
        })
        return result.first!
    }
    
    static func find(id: Int64) throws -> Self {
        if Meta.hasLocalInstanceContextFor(self, hash: id) {
            return Self(localID: id)
        }
        
        let result = try self.connectForFetch(error: SQLiteModelError.FetchError, connectionBlock: { connection in
            guard let row = connection.pluck(self.query.filter(self.localIDExpression == id)) else {
                throw SQLiteModelError.FetchError
            }
            let localID = row[self.localIDExpression]
            if let _ = Meta.localInstanceContextForModel(self, hash: localID) {} else {
                Meta.createLocalInstanceContextFor(self, row: row)
            }
            let instance = Self(localID: localID)
            return [instance]
        })
        guard result.count == 1 else {
            throw SQLiteModelError.FetchError
        }
        return result[0]
    }
    
    final static func fetchAll() throws -> [Self] {
        let result = try self.fetch(self.query)
        return result
    }
    
    final static func fetch(query: QueryType) throws -> [Self] {
        let result = try self.connectForFetch(error: SQLiteModelError.FetchError, connectionBlock: { connection in
            let rows = try connection.prepare(query)
            var fetchedInstances: [Self] = []
            for row in rows {
                let localID = row[self.localIDExpression]
                Meta.createLocalInstanceContextFor(self, row: row)
                let instance = Self(localID: localID)
                fetchedInstances.append(instance)
            }
            return fetchedInstances
        })
        return result
    }
    
    private static func sqlmdl_update(query: QueryType, setters: [Setter], relationshipSetters: [RelationshipSetter]) throws -> Void {
        try self.connect(error: SQLiteModelError.UpdateError, connectionBlock: { connection in
            
            func __update() throws {
                if setters.count > 0 {
                    try connection.run(query.update(setters))
                }
            }
            
            if relationshipSetters.count > 0 {
                try __update()
                let instances = try self.fetch(query)
                for instance in instances {
                    for relationshipSetter in relationshipSetters {
                        relationshipSetter.action(instance)
                    }
                }
            }
            else {
                let rows = try connection.prepare(query)
                try __update()
                for row in rows {
                    Meta.createLocalInstanceContextFor(self, row: row)
                }
            }
        })
    }
    
    final static func update(query: QueryType, setters: [Setter] = [], relationshipSetters: [RelationshipSetter] = []) throws -> Void {
        try self.sqlmdl_update(query, setters: setters, relationshipSetters: relationshipSetters)
    }
    
    final static func updateAll(setters: [Setter] = [], relationshipSetters: [RelationshipSetter] = []) throws -> Void {
        try self.sqlmdl_update(self.query, setters: setters, relationshipSetters: relationshipSetters)
    }
    
    init(localID: Int64 = -1) {
        self.init()
        self.localID = localID
    }
    
    final mutating func save() throws {
        try self.connect(error: SQLiteModelError.UpdateError, connectionBlock: { (connection) -> Void in
            let now = NSDate()
            var setters = Meta.settersForModel(self.dynamicType, hash: self.localID)
            setters.append(self.dynamicType.localUpdatedAtExpression <- now)
            try connection.run(self.instanceQuery.update(setters))
            guard let row = connection.pluck(self.dynamicType.table.select(distinct: *).filter(self.dynamicType.localIDExpression == self.localID)) else {
                throw SQLiteModelError.UpdateError
            }
            Meta.createLocalInstanceContextFor(self.dynamicType, row: row)
        })
    }
    
    final func delete() throws {
        try self.connect(error: SQLiteModelError.DeleteError, connectionBlock: { (connection) -> Void in
            try connection.run(self.instanceQuery.delete())
            Meta.removeLocalInstanceContextFor(self.dynamicType, hash: self.localID)
        })
    }
    
    // Get
    
    final func get<V: Value>(column: Expression<V>) -> V {
        return self.get(Expression<V?>(column))!
    }
    
    final func get<V: SQLite.Value>(column: Expression<V?>) -> V? {
        let value = Meta.getValueForModel(self.dynamicType, hash: self.localID, expression: column)
        return value
    }
    
    func get<V: SQLiteModel>(column: Relationship<V>) -> V {
        return self.get(Relationship<V?>(column))!
    }
    
    func get<V: SQLiteModel>(column: Relationship<V?>) -> V? {
        return Meta.getRelationshipForModel(self.dynamicType, hash: self.localID, relationship: column)
    }
    
    func get<V: SQLiteModel>(column: Relationship<[V]>) -> [V] {
        return Meta.getRelationshipForModel(self.dynamicType, hash: self.localID, relationship: column)
    }
    
    // Set
    
    final func set<V: Value>(column: Expression<V>, value: V) {
        self.set(Expression<V?>(column), value: value)
    }
    
    final func set<V: Value>(column: Expression<V?>, value: V?) {
        Meta.setValueForModel(self.dynamicType, hash: self.localID, column: column, value: value)
    }
    
    func set<V: SQLiteModel>(column: Relationship<V>, value: V) {
        self.set(Relationship<V?>(column), value: value)
    }
    
    func set<V: SQLiteModel>(column: Relationship<V?>, value: V?) {
        Meta.setRelationshipForModel(self.dynamicType, relationship: column, value: (self, value))
    }
    
    func set<V: SQLiteModel>(column: Relationship<[V]>, value: [V]) {
        Meta.setRelationshipForModel(self.dynamicType, relationship: column, value: (self, value))
    }
}