//
//  SQLiteExtensions.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 1/5/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import Foundation
import SQLite

// MARK: Value

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
            LogManager.log("Failure: fromDatatypeValue: could not fetch instance using localID")
            return nil
        }
    }
    
    public var datatypeValue: Int64 {
        return self.localID
    }
}

//extension Row {
//    
//    internal func smartGet<V: Value>(column: Expression<V>, shouldNamespace: Bool, table: QueryType) -> V {
//        return self.smartGet(Expression<V?>(column), shouldNamespace: shouldNamespace, table: table)!
//    }
//    
//    internal func smartGet<V: Value>(column: Expression<V?>, shouldNamespace: Bool, table: QueryType) -> V? {
//        if shouldNamespace {
//            return self.get(table.namespace(column))
//        }
//        else {
//            return self.get(column)
//        }
//    }
//}

// MARK: Relationship Tables

extension TableBuilder {
    
    public func relationship<U : SQLiteModel, V : SQLiteModel>(column: Relationship<V>, mappedFrom model: U.Type) {
        self.relationship(Relationship<V?>(column), mappedFrom: model)
    }
    
    public func relationship<U : SQLiteModel, V : SQLiteModel>(column: Relationship<V?>, mappedFrom model: U.Type) {
        Meta.createRelationshipForModel(model, relationship: column)
    }
    
    public func relationship<U : SQLiteModel, V : SQLiteModel>(column: Relationship<[V]>, mappedFrom model: U.Type) {
        Meta.createRelationshipForModel(model, relationship: column)
    }
}
