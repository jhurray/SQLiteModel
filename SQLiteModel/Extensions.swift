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
        return SQLiteModelID.declaredDatatype
    }
    
    public static func fromDatatypeValue(datatypeValue: SQLiteModelID) -> Self? {
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
    
    public var datatypeValue: SQLiteModelID {
        return self.localID
    }
}

extension Float: Value {
    public static var declaredDatatype: String {
        return Double.declaredDatatype
    }
    public static func fromDatatypeValue(doubleValue: Double) -> Float {
        return Float(Double.fromDatatypeValue(doubleValue))
    }
    public var datatypeValue: Double {
        return Double(self)
    }
}

// MARK: TableBuilder (Relationship<T>)

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
