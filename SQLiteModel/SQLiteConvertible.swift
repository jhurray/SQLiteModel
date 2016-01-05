//
//  SQLiteConvertible.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 12/28/15.
//  Copyright © 2015 jhurray. All rights reserved.
//

import Foundation
import SQLite

public enum SQLiteConvertibleMappingError: ErrorType {
    case MappingSQLToModelError
    case MappingModelToSQLError
}

internal enum SQLiteConvertibleContextType {
    case SQLToModel
    case ModelToSQL
}

public struct SQLiteConvertibleContext {
    
    internal let type: SQLiteConvertibleContextType
    internal var row: Row?
    private(set) var setters: [Setter]
    
    internal init(type: SQLiteConvertibleContextType = .ModelToSQL, row: Row? = nil) {
        self.type = type
        self.row = row
        self.setters = [Setter]()
    }
    
    internal mutating func map<V : Value>(inout value value: V, expression: Expression<V>) throws -> Void {
        switch self.type {
        case .ModelToSQL:
            guard let setter: Setter = expression <- value else {
                throw SQLiteConvertibleMappingError.MappingModelToSQLError
            }
            self.setters.append(setter)
            break
        case .SQLToModel:
            guard let row = self.row else {
                throw SQLiteConvertibleMappingError.MappingSQLToModelError
            }
            value = row.get(expression)
        }
    }
    
    internal mutating func map<V : Value>(inout value value: V, expression: Expression<V?>) throws -> Void {
        switch self.type {
        case .ModelToSQL:
            guard let setter: Setter = expression <- value else {
                throw SQLiteConvertibleMappingError.MappingModelToSQLError
            }
            self.setters.append(setter)
            break
        case .SQLToModel:
            guard let row = self.row else {
                throw SQLiteConvertibleMappingError.MappingSQLToModelError
            }
            value = row.get(expression)!
        }
    }
}


// Mark: Methods to override
public protocol SQLiteConvertible {
    
    static var tableName : String {get}
    static func buildTable(tableBuilder: TableBuilder) -> Void
    static func instance() -> Self
    mutating func mapSQLite(inout context: SQLiteConvertibleContext) throws -> Void
    
}

