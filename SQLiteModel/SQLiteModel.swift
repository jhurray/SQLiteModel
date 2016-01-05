//
//  SQLiteModel.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 12/24/15.
//  Copyright © 2015 jhurray. All rights reserved.
//

import Foundation
import SQLite

// MARK: Exposed Methods

public protocol SQLiteModel : SQLiteConvertible {
    
    // Query
    static var query: QueryType {get}
    
    // Static Methods
    static func createTable() throws -> Void
    static func dropTable() throws -> Void
    
    static func deleteAll() throws -> Void
    static func delete(query: QueryType) throws -> Void
    
    static func fetchAll() throws -> [Self]
    static func fetch(query: QueryType) throws -> [Self]
    
    static func updateAll(values: Setter...) throws -> Void
    static func update(query: QueryType, values: Setter...) throws -> Void
    
    // Instance Methods
    mutating func save() throws
    func delete() throws
    
    // Local Context
    var localID: Int64? {get set}
    var localCreatedAt: NSDate? {get}
    var localUpdatedAt: NSDate? {get}
}

// MARK: Internal Context

internal extension SQLiteModel {
    
    internal static var tableName : String {
        return Meta.tableNameForModel(self)
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
    
    internal static func instanceQueryWithLocalID(localID: Int64?) -> QueryType? {
        guard let localID = localID else {return nil}
        let instance = self.table.filter(self.localIDExpression == localID)
        return instance
    }
    
    internal var instanceQuery: QueryType? {
        return self.dynamicType.instanceQueryWithLocalID(self.localID)
    }
    
    var localCreatedAt: NSDate? {
        guard let localID = self.localID else {return nil}
        return Meta.localCreatedAtForModel(self.dynamicType, hash: localID)
    }
    
    var localUpdatedAt: NSDate? {
        guard let localID = self.localID else {return nil}
        return Meta.localUpdatedAtForModel(self.dynamicType, hash: localID)
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
            error.logError(self, model: instance, error: caughtError)
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
            error.logError(self, model: instance, error: caughtError)
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
            try connection.run(self.table.create(temporary: false, ifNotExists: true, block: { tableBuilder in
                tableBuilder.column(self.localIDExpression, primaryKey: .Autoincrement)
                tableBuilder.column(self.localCreatedAtExpression)
                tableBuilder.column(self.localUpdatedAtExpression)
                self.buildTable(tableBuilder)
            }))
        })
    }
    
    final static func dropTable() throws -> Void {
        
        try self.connect(error: SQLiteModelError.DropError, connectionBlock: { connection in
            try connection.run(self.table.drop(ifExists: true))
        })
    }
    
    final static func deleteAll() throws -> Void {
        try self.delete(self.query)
    }
    
    static func delete(query: QueryType) throws -> Void {
        
        try self.connect(error: SQLiteModelError.DeleteError, connectionBlock: { connection in
            try connection.run(query.delete())
        })
    }
    
    final static func fetchAll() throws -> [Self] {
        let result = try self.fetch(self.query)
        return result
    }
    
    final static func fetch(query: QueryType) throws -> [Self] {
        let result = try self.connectForFetch(error: SQLiteModelError.FetchError, connectionBlock: { connection in
            let rows = connection.prepare(query)
            var fetchedInstances: [Self] = []            
            for row in rows {
                var context = SQLiteConvertibleContext(type: .SQLToModel, row: row)
                var instance = self.instance()
                try instance.mapSQLite(&context)
                instance.localID = row[self.localIDExpression]
                if let _ = instance.localCreatedAt, let _ = instance.localUpdatedAt {} else {
                    Meta.createLocalInstanceContextFor(self, row: row)
                }
                fetchedInstances.append(instance)
            }
            return fetchedInstances
        })
        return result
    }
    
    private static func sqlmdl_update(query: QueryType, values: [Setter]) throws -> Void {
        try self.connect(error: SQLiteModelError.UpdateError, connectionBlock: { connection in
            try connection.run(query.update(values))
        })
    }
    
    final static func update(query: QueryType, values: Setter...) throws -> Void {
        try self.sqlmdl_update(query, values: values)
    }
    
    final static func updateAll(values: Setter...) throws -> Void {
        try self.sqlmdl_update(self.query, values: values)
    }
    
    final mutating func save() throws {
        let error = (self.localID == nil) ? SQLiteModelError.InsertError : SQLiteModelError.UpdateError
        try self.connect(error: error, connectionBlock: { (connection) -> Void in
            
            var context = SQLiteConvertibleContext()
            try self.mapSQLite(&context)
            var setters = context.setters
            let now = NSDate()
            
            if let instance = self.instanceQuery, localID = self.localID {
                try Meta.updateLocalInstanceContextForModel(self.dynamicType, hash: localID)
                setters.append(self.dynamicType.localUpdatedAtExpression <- now)
                try connection.run(instance.update(setters))
            }
            else {
                setters.append(self.dynamicType.localCreatedAtExpression <- now)
                setters.append(self.dynamicType.localUpdatedAtExpression <- now)
                let rowID = try connection.run(self.dynamicType.table.insert(or: OnConflict.Replace, setters))
                guard let row = connection.pluck(self.dynamicType.table.select(distinct: *).filter(rowid == rowID)) else {
                    throw SQLiteModelError.InsertError
                }
                let localID = row[self.dynamicType.localIDExpression]
                self.localID = localID
                Meta.createLocalInstanceContextFor(self.dynamicType, row: row)
            }
        })
    }
    
    final func delete() throws {
        
        try self.connect(error: SQLiteModelError.DeleteError, connectionBlock: { (connection) -> Void in
            guard let instance = self.instanceQuery else {throw SQLiteModelError.DeleteError}
            try connection.run(instance.delete())
        })
        
    }
}
