//
//  Operators.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 3/29/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import Foundation
import SQLite


// MARK: <|  |>

infix operator <| {associativity left}
infix operator |> {associativity left}

public func <| <U: SQLiteModel, V: Value>(lhs: U, rhs: Expression<V>) -> (U, Expression<V>) {
    return (lhs, rhs)
}

public func |> <U: SQLiteModel, V: Value>(lhs: (U, Expression<V>), rhs: V) -> Void {
    lhs.0.set(lhs.1, value: rhs)
}

public func <| <U: SQLiteModel, V: Value>(lhs: U, rhs: Expression<V?>) -> (U, Expression<V?>) {
    return (lhs, rhs)
}

public func |> <U: SQLiteModel, V: Value>(lhs: (U, Expression<V?>), rhs: V?) -> Void {
    lhs.0.set(lhs.1, value: rhs)
}

public func <| <U: SQLiteModel, V: SQLiteModel>(lhs: U, rhs: Relationship<V>) -> (U, Relationship<V>) {
    return (lhs, rhs)
}

public func |> <U: SQLiteModel, V: SQLiteModel>(lhs: (U, Relationship<V>), rhs: V) -> Void {
    lhs.0.set(lhs.1, value: rhs)
}

public func <| <U: SQLiteModel, V: SQLiteModel>(lhs: U, rhs: Relationship<V?>) -> (U, Relationship<V?>) {
    return (lhs, rhs)
}

public func |> <U: SQLiteModel, V: SQLiteModel>(lhs: (U, Relationship<V?>), rhs: V?) -> Void {
    lhs.0.set(lhs.1, value: rhs)
}

public func <| <U: SQLiteModel, V: SQLiteModel>(lhs: U, rhs: Relationship<[V]>) -> (U, Relationship<[V]>) {
    return (lhs, rhs)
}

public func |> <U: SQLiteModel, V: SQLiteModel>(lhs: (U, Relationship<[V]>), rhs: [V]) -> Void {
    lhs.0.set(lhs.1, value: rhs)
}


// MARK: =>

infix operator => {}

public func => <U: SQLiteModel, V: Value>(lhs: U, rhs: Expression<V?>) -> V? {
    return lhs.get(rhs)
}

public func => <U: SQLiteModel, V: Value>(lhs: U, rhs: Expression<V>) -> V {
    return lhs.get(rhs)
}

public func => <U: SQLiteModel, V: SQLiteModel>(lhs: U, rhs: Relationship<V?>) -> V? {
    return lhs.get(rhs)
}

public func => <U: SQLiteModel, V: SQLiteModel>(lhs: U, rhs: Relationship<V>) -> V {
    return lhs.get(rhs)
}

public func => <U: SQLiteModel, V: SQLiteModel>(lhs: U, rhs: Relationship<[V]>) -> [V] {
    return lhs.get(rhs)
}

// MARK: <- (Relationship Setters)

public func <- <V: SQLiteModel>(column: Relationship<V>, value: V) -> RelationshipSetter {
    return RelationshipSetter(action: { (model: SQLiteConvertible) -> Void in
        model.set(column, value: value)
    })
}

public func <- <V: SQLiteModel>(column: Relationship<V?>, value: V?) -> RelationshipSetter {
    return RelationshipSetter(action: { (model: SQLiteConvertible) -> Void in
        model.set(column, value: value)
    })
}

public func <- <V: SQLiteModel>(column: Relationship<[V]>, value: [V]) -> RelationshipSetter {
    return RelationshipSetter(action: { (model: SQLiteConvertible) -> Void in
        model.set(column, value: value)
    })
}
