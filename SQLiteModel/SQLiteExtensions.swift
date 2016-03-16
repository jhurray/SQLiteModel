//
//  SQLiteExtensions.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 1/5/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import Foundation
import SQLite

extension SQLiteModel {
    
    public static var declaredDatatype: String {
        return "INTEGER"
    }
    
    public static func fromDatatypeValue(datatypeValue: Int64) -> Self? {
        do {
            let query = self.query.filter(self.localIDExpression == datatypeValue).limit(1, offset: 0)
            guard let instance = try self.fetch(query).first else {
                throw SQLiteModelError.FetchError
            }
            return instance
        }
        catch {
            print("Failure: fromDatatypeValue: could not fetch instance using localID")
            return nil
        }
    }
    
    public var datatypeValue: Int64 {
        return self.localID
    }
}

extension Row {
    
    internal func smartGet<V: Value>(column: Expression<V>, shouldNamespace: Bool, table: QueryType) -> V {
        return self.smartGet(Expression<V?>(column), shouldNamespace: shouldNamespace, table: table)!
    }
    
    internal func smartGet<V: Value>(column: Expression<V?>, shouldNamespace: Bool, table: QueryType) -> V? {
        if shouldNamespace {
            return self.get(table.namespace(column))
        }
        else {
            return self.get(column)
        }
    }
}

extension TableBuilder {
    
    public func relationship<T : SQLiteModel, V : SQLiteModel>(column: Relationship<T>, references model: V.Type, update: Dependency? = nil, delete: Dependency? = nil) {
        self.column(column.referenceExpression)
        self.foreignKey(column.referenceExpression, references: V.table, V.localIDExpression, update: update, delete: delete)
    }
    
    public func relationship<T : SQLiteModel, V : SQLiteModel>(column: Relationship<T?>, references model: V.Type, update: Dependency? = nil, delete: Dependency? = nil) {
        self.column(column.referenceExpression)
        self.foreignKey(column.referenceExpression, references: V.table, V.localIDExpression, update: update, delete: delete)
    }
}
