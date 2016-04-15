//
//  Operators.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 3/29/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import Foundation
import SQLite


// MARK: SQLiteModel Setters  <|  |> (sync) <| |* (async)

/*

Usage:

// Sync:
model <| ModelType.Column |> value

// Async:
model <| ModelType.Column |* value

*/

infix operator <| {associativity left}
infix operator |> {associativity left}
infix operator |* {associativity left}

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

public func |* <U: SQLiteModel, V: SQLiteModel>(lhs: (U, Relationship<V>), rhs: V) -> Void {
    lhs.0.setInBackground(lhs.1, value: rhs)
}

public func <| <U: SQLiteModel, V: SQLiteModel>(lhs: U, rhs: Relationship<V?>) -> (U, Relationship<V?>) {
    return (lhs, rhs)
}

public func |> <U: SQLiteModel, V: SQLiteModel>(lhs: (U, Relationship<V?>), rhs: V?) -> Void {
    lhs.0.set(lhs.1, value: rhs)
}

public func |* <U: SQLiteModel, V: SQLiteModel>(lhs: (U, Relationship<V?>), rhs: V?) -> Void {
    lhs.0.setInBackground(lhs.1, value: rhs)
}

public func <| <U: SQLiteModel, V: SQLiteModel>(lhs: U, rhs: Relationship<[V]>) -> (U, Relationship<[V]>) {
    return (lhs, rhs)
}

public func |> <U: SQLiteModel, V: SQLiteModel>(lhs: (U, Relationship<[V]>), rhs: [V]) -> Void {
    lhs.0.set(lhs.1, value: rhs)
}

public func |* <U: SQLiteModel, V: SQLiteModel>(lhs: (U, Relationship<[V]>), rhs: [V]) -> Void {
    lhs.0.setInBackground(lhs.1, value: rhs)
}


// MARK: SQLiteModel Getters  => (sync) ~* (async)

infix operator => {}
infix operator ~* {associativity left}
/*

Usage:

// Sync
model => ModelType.Column

// Async
model ~* (ModelType.Column, { value in
    // do something with value
})

// is the same as

model ~* Model.Column ~* { value in
    // do something with value
}

*/

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

// Ordered by localID Ascending
public func => <U: SQLiteModel, V: SQLiteModel>(lhs: U, rhs: Relationship<[V]>) -> [V] {
    return lhs.get(rhs)
}

public func ~* <U: SQLiteModel, V: SQLiteModel>(lhs: U, rhs: (Relationship<V?>, (V?) -> Void))  {
    lhs.getInBackground(rhs.0, completion: rhs.1)
}

public func ~* <U: SQLiteModel, V: SQLiteModel>(lhs: U, rhs: (Relationship<V>, (V) -> Void))  {
    lhs.getInBackground(rhs.0, completion: rhs.1)
}

// Ordered by localID Ascending
public func ~* <U: SQLiteModel, V: SQLiteModel>(lhs: U, rhs: (Relationship<[V]>, ([V]) -> Void))  {
    lhs.getInBackground(rhs.0, completion: rhs.1)
}

public func ~* <U: SQLiteModel, V: SQLiteModel>(lhs: U, rhs: Relationship<V?>) -> (U, Relationship<V?>)  {
    return (lhs, rhs)
}

public func ~* <U: SQLiteModel, V: SQLiteModel>(lhs: U, rhs: Relationship<V>) -> (U, Relationship<V>)  {
    return (lhs, rhs)
}

public func ~* <U: SQLiteModel, V: SQLiteModel>(lhs: U, rhs: Relationship<[V]>) -> (U, Relationship<[V]>)  {
    return (lhs, rhs)
}

public func ~* <U: SQLiteModel, V: SQLiteModel>(lhs: (U, Relationship<V?>), rhs: (V?) -> Void) {
    lhs.0.getInBackground(lhs.1, completion: rhs)
}

public func ~* <U: SQLiteModel, V: SQLiteModel>(lhs: (U, Relationship<V>), rhs: (V) -> Void) {
    lhs.0.getInBackground(lhs.1, completion: rhs)
}

// Ordered by localID Ascending
public func ~* <U: SQLiteModel, V: SQLiteModel>(lhs: (U, Relationship<[V]>), rhs: ([V]) -> Void) {
    lhs.0.getInBackground(lhs.1, completion: rhs)
}


// MARK: <- (Relationship Setters)

/*

Usage:

ModelType.RelationshipColumn <- value

*/

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
