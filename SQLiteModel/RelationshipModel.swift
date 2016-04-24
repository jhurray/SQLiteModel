//
//  SQLiteRelationshipModel.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 3/15/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import Foundation
import SQLite

struct RelationshipColumns {
    static let LeftID = Expression<SQLiteModelID>("left_id")
    static let RightID = Expression<SQLiteModelID>("right_id")
}

internal protocol RelationshipModel : SQLiteModel {
    
    associatedtype LeftModel: SQLiteModel
    associatedtype RightModel: SQLiteModel
    
    static func initialize() -> Void
    static func removeLeft(leftID: SQLiteModelID) -> Void
    static func removeRight(rightID: SQLiteModelID) -> Void
    static func removeMultipleRight(rightIDs: [SQLiteModelID]) -> Void
    
    static var unique: Bool {get}
}

extension RelationshipModel {
    
    internal static var tableName: String {
        let leftName = String(LeftModel).lowercaseString
        let rightName = String(RightModel).lowercaseString
        let addition = RelationshipReferenceTracker.currentTemplate((LeftModel.self, RightModel.self))
        return "\(leftName)_rel_map_\(rightName)_\(addition)"
    }
    
    static var unique: Bool {
        return false
    }
    
    final static func removeLeft(leftID: SQLiteModelID) -> Void {
        let query = self.table.filter(RelationshipColumns.LeftID == leftID)
        let _ = try? self.delete(query)
    }
    
    static func removeRight(rightID: SQLiteModelID) -> Void {
        let query = self.table.filter(RelationshipColumns.RightID == rightID)
        let _ = try? self.delete(query)
    }
    
    static func removeMultipleRight(rightIDs: [SQLiteModelID]) -> Void {
        let query = self.table.filter(rightIDs.contains(RelationshipColumns.RightID))
        let _ = try? self.delete(query)
    }
    
    private static func finishBuildTable(tableBuilder: TableBuilder) -> Void {
        tableBuilder.unique([RelationshipColumns.LeftID, RelationshipColumns.RightID])
        tableBuilder.foreignKey(RelationshipColumns.LeftID, references: LeftModel.table, LeftModel.localIDExpression, delete: TableBuilder.Dependency.Cascade)
        tableBuilder.foreignKey(RelationshipColumns.RightID, references: RightModel.table, RightModel.localIDExpression, delete: TableBuilder.Dependency.Cascade)
    }
}

protocol SingularRelationshipModel : RelationshipModel {
    static func getRelationship(leftID: SQLiteModelID) -> RightModel?
    static func setRelationship(left: LeftModel, right: RightModel)
}

extension SingularRelationshipModel {
    
    static func getRelationship(leftID: SQLiteModelID) -> RightModel? {
        
        guard let rightID = Meta.queryCachedValueForSingularRelationship(self, queryColumn: RelationshipColumns.LeftID, queryValue: leftID, returnColumn: RelationshipColumns.RightID) else {
            return nil
        }
        return RightModel(localID: rightID)
    }
    
    final static func setRelationship(left: LeftModel, right: RightModel) {
        
        if Meta.hasLocalInstanceContextForSingularRelationhip(self, leftID: left.localID) {
            let setters = [
                RelationshipColumns.RightID <- right.localID,
            ]
            let query = self.query.filter(RelationshipColumns.LeftID == left.localID)
            try! self.update(query, setters: setters)
        }
        else {
            self.removeLeft(left.localID)
            if self.unique {
                self.removeRight(right.localID)
            }
            let setters = [
                RelationshipColumns.LeftID <- left.localID,
                RelationshipColumns.RightID <- right.localID,
            ]
            let _ = try! self.new(setters).localID
        }
    }
    
    static func initialize() -> Void {
        let _ = try? self.createTable()
        let _ = try? self.createIndex([RelationshipColumns.LeftID], unique: true)
    }
}

internal struct SingularRelationship<Left : SQLiteModel, Right : SQLiteModel> : SingularRelationshipModel {
    
    typealias LeftModel = Left
    typealias RightModel = Right
    
    var localID: SQLiteModelID = -1
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(RelationshipColumns.LeftID, unique: true) 
        tableBuilder.column(RelationshipColumns.RightID)
        self.finishBuildTable(tableBuilder)
    }
}

internal struct UniqueSingularRelationship<Left : SQLiteModel, Right : SQLiteModel> : SingularRelationshipModel {
    
    typealias LeftModel = Left
    typealias RightModel = Right
    
    var localID: SQLiteModelID = -1
    
    static var unique: Bool {
        return true
    }
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(RelationshipColumns.LeftID, unique: true)
        tableBuilder.column(RelationshipColumns.RightID, unique: true)
        self.finishBuildTable(tableBuilder)
    }
}

protocol MultipleRelationshipModel : RelationshipModel {
    static func getRelationship(leftID: SQLiteModelID) -> [RightModel]
    static func setRelationship(left: LeftModel, right: [RightModel])
}

extension MultipleRelationshipModel {
    
    static func getRelationship(leftID: SQLiteModelID) -> [RightModel] {
        
        let rightIDs = Meta.queryCachedValueForRelationship(self, queryColumn: RelationshipColumns.LeftID, queryValue: leftID, returnColumn: RelationshipColumns.RightID)
        let cachedIDsSplit = Meta.queryCachedInstanceIDsFor(RightModel.self, hashes: rightIDs.sort{ $0 < $1})
        var instances: [RightModel] = cachedIDsSplit.0.map { RightModel(localID: $0) }
        if cachedIDsSplit.1.count > 0 {
            let query = RightModel.table.filter(rightIDs.contains(RightModel.localIDExpression))
            guard let fetchedInstances = try? RightModel.fetch(query) else {
                return instances
            }
            instances += fetchedInstances
        }
        return instances
    }
    
    static func setRelationship(left: LeftModel, right: [RightModel]) {
        self.removeLeft(left.localID)
        if self.unique {
            self.removeMultipleRight(right.map({ $0.localID }))
        }
        guard right.count > 0 else {
            return
        }
        let now = NSDate()
        let dateString = dateFormatter.stringFromDate(now)
        var statement = "INSERT INTO \(self.tableName) (left_id, right_id, sqlmdl_localCreatedAt, sqlmdl_localUpdatedAt) VALUES"
        for rightID in right.map({ $0.localID }) {
            statement += " (\(left.localID), \(rightID), '\(dateString)', '\(dateString)'),"
        }
        statement.removeAtIndex(statement.characters.endIndex.predecessor())
        statement += ";"
        
        let _ = try? self.connect(error: SQLiteModelError.InsertError, connectionBlock: { connection in
            try connection.execute(statement)
            let query = self.query.filter(RelationshipColumns.LeftID == left.localID)
            for row in try connection.prepare(query) {
                Meta.createLocalInstanceContextFor(self, row: row)
            }
        })
    }
    
    static func initialize() -> Void {
        let _ = try? self.createTable()
        let _ = try? self.createIndex([RelationshipColumns.LeftID], unique: false)
    }
}

internal struct MultipleRelationship<Left : SQLiteModel, Right : SQLiteModel> : MultipleRelationshipModel {
    
    typealias LeftModel = Left
    typealias RightModel = Right
    
    var localID: SQLiteModelID = -1
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(RelationshipColumns.LeftID)
        tableBuilder.column(RelationshipColumns.RightID)
        self.finishBuildTable(tableBuilder)
    }
    
    static func initialize() {
        let _ = try? self.createTable()
        let _ = try? self.createIndex([RelationshipColumns.LeftID], unique: false)
    }
}

internal struct UniqueMultipleRelationship<Left : SQLiteModel, Right : SQLiteModel> : MultipleRelationshipModel {
    
    typealias LeftModel = Left
    typealias RightModel = Right
    
    var localID: SQLiteModelID = -1
    
    static var unique: Bool {
        return true
    }
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(RelationshipColumns.LeftID)
        tableBuilder.column(RelationshipColumns.RightID, unique: true)
        self.finishBuildTable(tableBuilder)
    }
    
    static func initialize() {
        let _ = try? self.createTable()
        let _ = try? self.createIndex([RelationshipColumns.LeftID], unique: false)
    }
}
