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

public protocol SQLiteModel : SQLiteConvertible, Value {
    
    // Table
    static var tableName : String {get}
    
    // Query
    static var query: QueryType {get}
    
    // Static Methods
    static func createTable() throws -> Void
    static func dropTable() throws -> Void
    
    static func new(setters: [Setter], relationshipSetters: [RelationshipSetter]) throws -> Self
    
    static func deleteAll() throws -> Void
    static func delete(query: QueryType) throws -> Void
    
    static func find(id: Int64) throws -> Self
    static func fetchAll() throws -> [Self]
    static func fetch(query: QueryType) throws -> [Self]
    
    static func updateAll(setters: [Setter], relationshipSetters: [RelationshipSetter]) throws -> Void
    static func update(query: QueryType, setters: [Setter], relationshipSetters: [RelationshipSetter]) throws -> Void
    
    // Instance Methods
    init()
    mutating func save() throws
    func delete() throws
    
    func get<V: Value>(column: Expression<V>) -> V
    func get<V: Value>(column: Expression<V?>) -> V?
    func get<V: SQLiteModel>(column: Relationship<V>) -> V
    func get<V: SQLiteModel>(column: Relationship<V?>) -> V?
    func get<V: SQLiteModel>(column: Relationship<[V]>) -> [V]
    
    func set<V: Value>(column: Expression<V>, value: V)
    func set<V: Value>(column: Expression<V?>, value: V?)
    func set<V: SQLiteModel>(column: Relationship<V>, value: V)
    func set<V: SQLiteModel>(column: Relationship<V?>, value: V?)
    func set<V: SQLiteModel>(column: Relationship<[V]>, value: [V])
    
    // Local Context
    var localID: Int64 {get set}
    var localCreatedAt: NSDate? {get}
    var localUpdatedAt: NSDate? {get}
}
