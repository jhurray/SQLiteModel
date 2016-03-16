//
//  SQLiteConvertible.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 12/28/15.
//  Copyright © 2015 jhurray. All rights reserved.
//

import Foundation
import SQLite

//public enum SQLiteConvertibleMappingError: ErrorType {
//    case MappingSQLToModelError
//    case MappingModelToSQLError
//}
//
//internal enum SQLiteConvertibleContextType {
//    case SQLToModel
//    case ModelToSQL
//    case ContextPass
//}
//
//public struct SQLiteConvertibleContext {
//    
//    internal let table: QueryType
//    internal let type: SQLiteConvertibleContextType
//    internal var row: Row?
//    private(set) var setters: [Setter]
//    internal(set) var containsRelationships: Bool
//    
//    internal init(table:QueryType, type: SQLiteConvertibleContextType = .ContextPass, row: Row? = nil, containsRelationships: Bool = false) {
//        self.table = table
//        self.type = type
//        self.row = row
//        self.setters = [Setter]()
//        self.containsRelationships = containsRelationships
//    }
//    
//    // MARK: Expressions
//    
//    public mutating func map<V : Value>(inout value value: V, expression: Expression<V>) throws -> Void {
//        switch self.type {
//        case .ModelToSQL:
//            guard let setter: Setter = expression <- value else {
//                throw SQLiteConvertibleMappingError.MappingModelToSQLError
//            }
//            self.setters.append(setter)
//        case .SQLToModel:
//            guard let row = self.row else {
//                throw SQLiteConvertibleMappingError.MappingSQLToModelError
//            }
//            value = row.smartGet(expression, shouldNamespace: self.containsRelationships, table: table)
//        case .ContextPass:
//            // do nothing
//            break
//        }
//    }
//    
//    public mutating func map<V : Value>(inout value value: V?, expression: Expression<V?>) throws -> Void {
//        switch self.type {
//        case .ModelToSQL:
//            guard let setter: Setter = expression <- value else {
//                throw SQLiteConvertibleMappingError.MappingModelToSQLError
//            }
//            self.setters.append(setter)
//        case .SQLToModel:
//            guard let row = self.row else {
//                throw SQLiteConvertibleMappingError.MappingSQLToModelError
//            }
//            value = row.smartGet(expression, shouldNamespace: self.containsRelationships, table: table)
//        case .ContextPass:
//            // do nothing
//            break
//        }
//    }
//    
//    // MARK: One to One Relationships
//    
//    public mutating func map<V : SQLiteModel>(inout value value: V, relationship: Relationship<V>) throws -> Void {
//        switch self.type {
//        case .ModelToSQL:
//            guard let localID = value.localID, let setter: Setter = relationship.referenceExpression <- localID else {
//                throw SQLiteConvertibleMappingError.MappingModelToSQLError
//            }
//            self.setters.append(setter)
//        case .SQLToModel:
//            guard let row = self.row else {
//                throw SQLiteConvertibleMappingError.MappingSQLToModelError
//            }
//            guard let referenceID = row.smartGet(relationship.referenceExpression, shouldNamespace: self.containsRelationships, table: table) else {
//                // If the foreign key of a non-optional relationship is nil, throw an error
//                throw SQLiteConvertibleMappingError.MappingSQLToModelError
//            }
//            let query = V.query.filter(referenceID == V.localIDExpression)
//            let references = try V.fetch(query)
//            guard references.count == 1, let reference = references.first else {
//                throw SQLiteModelError.FetchError
//            }
//            value = reference
//        case .ContextPass:
//            self.containsRelationships = true
//        }
//    }
//    
//    public mutating func map<V : SQLiteModel>(inout value value: V?, relationship: Relationship<V?>) throws -> Void {
//        switch self.type {
//        case .ModelToSQL:
//            guard let localID = value?.localID, let setter: Setter = relationship.referenceExpression <- localID else {
//                throw SQLiteConvertibleMappingError.MappingModelToSQLError
//            }
//            self.setters.append(setter)
//        case .SQLToModel:
//            guard let row = self.row else {
//                throw SQLiteConvertibleMappingError.MappingSQLToModelError
//            }
//            guard let referenceID = row.smartGet(relationship.referenceExpression, shouldNamespace: self.containsRelationships, table: table) else {
//                // If the foreign key of a non-optional relationship is nil, the value should be nil
//                value = nil
//                return
//            }
//            let query = V.query.filter(referenceID == V.localIDExpression)
//            let references = try V.fetch(query)
//            guard references.count == 1, let reference = references.first else {
//                throw SQLiteModelError.FetchError
//            }
//            value = reference
//        case .ContextPass:
//            self.containsRelationships = true
//        }
//    }
//    
//    // MARK: Many to <One or Many> Relationships
//    
//    public mutating func map<V : SQLiteModel>(inout value value: Array<V>, relationship: Relationship<V>) throws -> Void {
//        switch self.type {
//        case .ModelToSQL:
//            
//            // jhtodo
//            break
//            
//        case .SQLToModel:
//            guard let row = self.row else {
//                throw SQLiteConvertibleMappingError.MappingSQLToModelError
//            }
//            guard let referenceID = row.smartGet(relationship.referenceExpression, shouldNamespace: self.containsRelationships, table: table) else {
//                // If the foreign key of a non-optional relationship is nil, throw an error
//                throw SQLiteConvertibleMappingError.MappingSQLToModelError
//            }
//            let query = V.query.filter(referenceID == V.localIDExpression)
//            let references = try V.fetch(query)
//            value = references
//        case .ContextPass:
//            self.containsRelationships = true
//        }
//    }
//    
//    public mutating func map<V : SQLiteModel>(inout value value: Array<V>?, relationship: Relationship<V?>) throws -> Void {
//        switch self.type {
//        case .ModelToSQL:
//
//            // jhtodo
//            break 
//            
//        case .SQLToModel:
//            guard let row = self.row else {
//                throw SQLiteConvertibleMappingError.MappingSQLToModelError
//            }
//            guard let referenceID = row.smartGet(relationship.referenceExpression, shouldNamespace: self.containsRelationships, table: table) else {
//                // If the foreign key of a non-optional relationship is nil, the value should be nil
//                value = nil
//                return
//            }
//            let query = V.query.filter(referenceID == V.localIDExpression)
//            let references = try V.fetch(query)
//            value = references
//        case .ContextPass:
//            self.containsRelationships = true
//        }
//    }
//}


// Mark: Methods to override
public protocol SQLiteConvertible {
    
    static var tableName : String {get}
    static func buildTable(tableBuilder: TableBuilder) -> Void
}

