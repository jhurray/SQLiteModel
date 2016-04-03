//
//  Relationship.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 1/17/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import Foundation
import SQLite

public struct Relationship<DataType> {
    
    internal typealias UnderlyingType = DataType
    internal var template: String
    internal var unique: Bool
    internal var reference: Int = -1
}

extension Relationship where DataType : SQLiteModel {
    
    public init(_ template: String, unique: Bool = false) {
        self.template = template
        self.unique = unique
    }
}

extension Relationship where DataType : CollectionType, DataType.Generator.Element : SQLiteModel {
    
    public init(_ template: String, unique: Bool = false) {
        self.template = template
        self.unique = unique
    }
}

extension Relationship where DataType : _OptionalType{
    internal init(_ relationship: Relationship<DataType.WrappedType>) {
        self.template = relationship.template
        self.unique = relationship.unique
    }
    
    public init(_ template: String,  unique: Bool = false) {
        self.template = template
        self.unique = unique
    }
}

public struct RelationshipSetter {
    internal let action: (SQLiteConvertible) -> Void
}

internal struct RelationshipReferenceTracker {
    
    private static var sharedInstance = RelationshipReferenceTracker()
    private var tracker = [String : String]()
    
    static func currentTemplate<U: SQLiteModel, V: SQLiteModel>(key: (U.Type, V.Type)) -> String {
        guard let value = self.sharedInstance.tracker["\(key.0)_\(key.1)"] else {
            fatalError("SQLiteModel Error: Improper table access for a relationship.")
        }
        return value
    }
    
    static func setTemplate<U: SQLiteModel, V: SQLiteModel>(key: (U.Type, V.Type), template: String) {
        self.sharedInstance.tracker["\(key.0)_\(key.1)"] = template
    }
}
