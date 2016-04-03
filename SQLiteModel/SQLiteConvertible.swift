//
//  SQLiteConvertible.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 12/28/15.
//  Copyright © 2015 jhurray. All rights reserved.
//

import Foundation
import SQLite

public protocol SQLiteConvertible {
    
    // MARK: Override
    static func buildTable(tableBuilder: TableBuilder) -> Void
    
    // MARK: Translations
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
}

