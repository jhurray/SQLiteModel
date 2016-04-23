//
//  SQLiteModel.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 12/24/15.
//  Copyright © 2015 jhurray. All rights reserved.
//

import Foundation
import SQLite

public typealias SQLiteModelID = Int64

public typealias Completion = (SQLiteModelError?) -> Void

public protocol SQLiteModelAbstract {
    // Mandatory Override
    static func buildTable(tableBuilder: TableBuilder) -> Void
    // Optional Override
    static func alterSchema(schemaUpdater: SchemaUpdater) -> Void
}

public protocol SQLiteConvertible: SQLiteModelAbstract {
    
    func get<V: Value>(column: Expression<V>) -> V
    func get<V: Value>(column: Expression<V?>) -> V?
    
    func get<V: SQLiteModel>(column: Relationship<V>) -> V
    func get<V: SQLiteModel>(column: Relationship<V?>) -> V?
    // Ordered by localID Ascending
    func get<V: SQLiteModel>(column: Relationship<[V]>) -> [V]
    
    func getInBackground<V: SQLiteModel>(column: Relationship<V>, completion: (V) -> Void)
    func getInBackground<V: SQLiteModel>(column: Relationship<V?>, completion: (V?) -> Void)
    // Ordered by localID Ascending
    func getInBackground<V: SQLiteModel>(column: Relationship<[V]>, completion: ([V]) -> Void)
    
    func set<V: Value>(column: Expression<V>, value: V)
    func set<V: Value>(column: Expression<V?>, value: V?)
    
    func set<V: SQLiteModel>(column: Relationship<V>, value: V)
    func set<V: SQLiteModel>(column: Relationship<V?>, value: V?)
    func set<V: SQLiteModel>(column: Relationship<[V]>, value: [V])
    
    func setInBackground<V: SQLiteModel>(column: Relationship<V>, value: V, completion: (Void -> Void)?)
    func setInBackground<V: SQLiteModel>(column: Relationship<V?>, value: V?, completion: (Void -> Void)?)
    func setInBackground<V: SQLiteModel>(column: Relationship<[V]>, value: [V], completion: (Void -> Void)?)
    
    static var tableName : String {get}
}

public protocol SQLiteTableOperations {
    static func createTable() throws -> Void
    static func createTableInBackground(completion: Completion?)
    
    static func createIndex(columns: [Expressible], unique: Bool) throws -> Void
    static func createIndexInBackground(columns: [Expressible], unique: Bool, completion: Completion?)
    
    static func dropTable() throws -> Void
    static func dropTableInBackground(completion: Completion?)
}

public protocol SQLiteCreatable {
    static func new(setters: [Setter], relationshipSetters: [RelationshipSetter]) throws -> Self
    static func newInBackground(setters: [Setter], relationshipSetters: [RelationshipSetter], completion: ((Self?, SQLiteModelError?) -> Void)?)
}

public protocol SQLiteDeletable {
    static func deleteAll() throws -> Void
    static func deleteAllInBackground(completion: Completion?) -> Void
    
    static func delete(query: QueryType) throws -> Void
    static func deleteInBackground(query: QueryType, completion: Completion?) -> Void
}

public protocol SQLiteUpdatable {
    static func updateAll(setters: [Setter], relationshipSetters: [RelationshipSetter]) throws -> Void
    static func updateAllInBackground(setters: [Setter], relationshipSetters: [RelationshipSetter], completion: Completion?)
    
    static func update(query: QueryType, setters: [Setter], relationshipSetters: [RelationshipSetter]) throws -> Void
    static func updateInBackground(query: QueryType, setters: [Setter], relationshipSetters: [RelationshipSetter], completion: Completion?)
}

public protocol SQLiteFetchable {
    static func find(id: SQLiteModelID) throws -> Self
    static func findInBackground(id: SQLiteModelID, completion: (Self?, SQLiteModelError?) -> Void)
    
    static func fetchAll() throws -> [Self]
    static func fetchAllInBackground(completion: ([Self], SQLiteModelError?) -> Void)
    
    static func fetch(query: QueryType) throws -> [Self]
    static func fetchInBackground(query: QueryType, completion: ([Self], SQLiteModelError?) -> Void)
}

public protocol SQLiteInstance {
    init()
    mutating func save() throws
    mutating func saveInBackground(completion: Completion?)
    
    func delete() throws
    func deleteInBackground(completion: Completion?)
    
    func countForRelationship<V: SQLiteModel>(column: Relationship<[V]>) -> Int
    
    var localID: SQLiteModelID {get set}
    var localCreatedAt: NSDate? {get}
    var localUpdatedAt: NSDate? {get}
}

public protocol SQLiteQueryable {
    // Returns a base query
    /// Select * from <table_name>
    static var query: QueryType {get}
}

public protocol SQLiteScalarQueryable {
    static func count() throws -> Int
    static func countInBackground(completion: (Int, SQLiteModelError?) -> Void)
}

public protocol SQLiteAtomic {
    static func transaction(execute: Void -> Void)
}

public protocol SQLiteModel:
SQLiteConvertible,
SQLiteTableOperations,
SQLiteCreatable,
SQLiteDeletable,
SQLiteFetchable,
SQLiteInstance,
SQLiteQueryable,
SQLiteScalarQueryable,
SQLiteAtomic,
Value
{}
