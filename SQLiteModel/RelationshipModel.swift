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
    static let LeftID = Expression<Int64>("left_id")
    static let RightID = Expression<Int64>("right_id")
}

internal protocol RelationshipModel : SQLiteModel {
    
    typealias LeftModel: SQLiteModel
    typealias RightModel: SQLiteModel
    
    static func initialize() -> Void
    static func removeLeft(leftID: Int64) -> Void
    static func removeRight(rightID: Int64) -> Void
}

extension RelationshipModel {
    
    internal static var tableName: String {
        let leftName = String(LeftModel).lowercaseString
        let rightName = String(RightModel).lowercaseString
        let addition = RelationshipReferenceTracker.currentTemplate((LeftModel.self, RightModel.self))
        return "\(leftName)_rel_map_\(rightName)_\(addition)"
    }
    
    final static func removeLeft(leftID: Int64) -> Void {
        let query = self.table.filter(self.localIDExpression == leftID)
        let _ = try? self.delete(query)
    }
    
    static func removeRight(rightID: Int64) -> Void {
        let query = self.table.filter(self.localIDExpression == rightID)
        let _ = try? self.delete(query)
    }
    
    private static func finishBuildTable(tableBuilder: TableBuilder) -> Void {
        tableBuilder.unique([RelationshipColumns.LeftID, RelationshipColumns.RightID])
        tableBuilder.foreignKey(RelationshipColumns.LeftID, references: LeftModel.table, LeftModel.localIDExpression, delete: TableBuilder.Dependency.Cascade)
        tableBuilder.foreignKey(RelationshipColumns.RightID, references: RightModel.table, RightModel.localIDExpression, delete: TableBuilder.Dependency.Cascade)
    }
}

protocol SingularRelationshipModel : RelationshipModel {
    static func getRelationship(leftID: Int64) -> RightModel?
    static func setRelationship(left: LeftModel, right: RightModel) -> Int64
}

extension SingularRelationshipModel {
    
    static func getRelationship(leftID: Int64) -> RightModel? {
        if let result = try? self.fetch(self.table.filter(RelationshipColumns.LeftID == leftID)) where result.count == 1 {
            guard let rightID = result.first?.get(RelationshipColumns.RightID),
            let instance = try? RightModel.find(rightID)
            else {
                return nil
            }
            return instance
        }
        return nil
    }
    
    final static func setRelationship(left: LeftModel, right: RightModel) -> Int64 {
        let _ = try? self.delete(self.table.filter(RelationshipColumns.LeftID == left.localID))
        let setters = [
            RelationshipColumns.LeftID <- left.localID,
            RelationshipColumns.RightID <- right.localID,
        ]
        return try! self.new(setters).localID
    }
    
    static func initialize() -> Void {
        let _ = try? self.createTable()
        let _ = try? self.createIndex([RelationshipColumns.LeftID], unique: true)
    }
}

internal struct SingularRelationship<Left : SQLiteModel, Right : SQLiteModel> : SingularRelationshipModel {
    
    typealias LeftModel = Left
    typealias RightModel = Right
    
    var localID: Int64 = -1
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(RelationshipColumns.LeftID, unique: true) 
        tableBuilder.column(RelationshipColumns.RightID)
        self.finishBuildTable(tableBuilder)
    }
}

internal struct UniqueSingularRelationship<Left : SQLiteModel, Right : SQLiteModel> : SingularRelationshipModel {
    
    typealias LeftModel = Left
    typealias RightModel = Right
    
    var localID: Int64 = -1
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(RelationshipColumns.LeftID, unique: true)
        tableBuilder.column(RelationshipColumns.RightID, unique: true)
        self.finishBuildTable(tableBuilder)
    }
}

protocol MultipleRelationshipModel : RelationshipModel {
    static func getRelationship(leftID: Int64) -> [RightModel]
    static func setRelationship(left: LeftModel, right: [RightModel]) -> [Int64]
}

extension MultipleRelationshipModel {
    
    static func getRelationship(leftID: Int64) -> [RightModel] {
        if let result = try? self.fetch(self.table.filter(RelationshipColumns.LeftID == leftID)) {
            let rightIDs = result.map({$0.get(RelationshipColumns.RightID)})
            let query = RightModel.table.filter(rightIDs.contains(RightModel.localIDExpression))
            guard let instances = try? RightModel.fetch(query) else {
                    return []
            }
            return instances
        }
        return []
    }
    
    static func setRelationship(left: LeftModel, right: [RightModel]) -> [Int64] {
        let _ = try? self.delete(self.table.filter(RelationshipColumns.LeftID == left.localID))
        var ids = [Int64]()
        for rightModel in right {
            let setters = [
                RelationshipColumns.LeftID <- left.localID,
                RelationshipColumns.RightID <- rightModel.localID,
            ]
            let id = try! self.new(setters).localID
            ids.append(id)
        }
        return ids
    }
    
    static func initialize() -> Void {
        let _ = try? self.createTable()
        let _ = try? self.createIndex([RelationshipColumns.LeftID], unique: false)
    }
}

internal struct MultipleRelationship<Left : SQLiteModel, Right : SQLiteModel> : MultipleRelationshipModel {
    
    typealias LeftModel = Left
    typealias RightModel = Right
    
    var localID: Int64 = -1
    
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
    
    var localID: Int64 = -1
    
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
