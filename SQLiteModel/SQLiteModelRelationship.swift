//
//  SQLiteModelRelationship.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 1/17/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import Foundation
import SQLite

public struct Relationship<DataType> : ExpressionType, Hashable {
    
    public typealias UnderlyingType = DataType
    
    public var template: String
    public var bindings: [Binding?]
    
    internal let referenceExpression : Expression<Int64?>
    
    public init(_ template: String, _ bindings: [Binding?]) {
        self.template = template.stringByReplacingOccurrencesOfString("\"", withString: "")
        self.bindings = bindings
        self.referenceExpression = Expression<Int64?>("\"\(self.template)_reference_id\"", bindings)
    }
    
    // MARK: Hashable
    public var hashValue: Int {
        return Int("\(self.template).\(DataType.self)")!
    }
    
}

public func <-<V : SQLiteModel>(column: Relationship<V>, value: V) -> Setter {
    let setter: Setter = column.referenceExpression <- value.localID
    return setter
}

public func <-<V : SQLiteModel>(column: Relationship<V?>, value: V) -> Setter {
    let setter: Setter = column.referenceExpression <- value.localID
    return setter
}

public func <-<V : SQLiteModel>(column: Relationship<V?>, value: V?) -> Setter {
    let setter: Setter = column.referenceExpression <- value?.localID
    return setter
}

public func ==<T>(left: Relationship<T>, right: Relationship<T>) -> Bool {
    return left.template == right.template && left.dynamicType == right.dynamicType
}