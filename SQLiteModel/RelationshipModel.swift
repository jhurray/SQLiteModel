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
    
    typealias LeftModel: SQLiteModel
    typealias RightModel: SQLiteModel
    
    static func initialize() -> Void
    static func removeLeft(leftID: SQLiteModelID) -> Void
    static func removeRight(rightID: SQLiteModelID) -> Void
}

extension RelationshipModel {
    
    internal static var tableName: String {
        let leftName = String(LeftModel).lowercaseString
        let rightName = String(RightModel).lowercaseString
        let addition = RelationshipReferenceTracker.currentTemplate((LeftModel.self, RightModel.self))
        return "\(leftName)_rel_map_\(rightName)_\(addition)"
    }
    
    final static func removeLeft(leftID: SQLiteModelID) -> Void {
        let query = self.table.filter(self.localIDExpression == leftID)
        let _ = try? self.delete(query)
    }
    
    static func removeRight(rightID: SQLiteModelID) -> Void {
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
    static func getRelationship(leftID: SQLiteModelID) -> RightModel?
    static func setRelationship(left: LeftModel, right: RightModel) -> SQLiteModelID
}

extension SingularRelationshipModel {
    
    static func getRelationship(leftID: SQLiteModelID) -> RightModel? {
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
    
    final static func setRelationship(left: LeftModel, right: RightModel) -> SQLiteModelID {
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
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(RelationshipColumns.LeftID, unique: true)
        tableBuilder.column(RelationshipColumns.RightID, unique: true)
        self.finishBuildTable(tableBuilder)
    }
}

protocol MultipleRelationshipModel : RelationshipModel {
    static func getRelationship(leftID: SQLiteModelID) -> [RightModel]
    static func setRelationship(left: LeftModel, right: [RightModel]) -> [SQLiteModelID]
}

extension MultipleRelationshipModel {
    
//    // BASELINE
//    static func getRelationship(leftID: SQLiteModelID) -> [RightModel] {
//        if let result = try? self.fetch(self.table.filter(RelationshipColumns.LeftID == leftID)) {
//            let rightIDs = result.map({$0.get(RelationshipColumns.RightID)})
//            let query = RightModel.table.filter(rightIDs.contains(RightModel.localIDExpression))
//            guard let instances = try? RightModel.fetch(query) else {
//                    return []
//            }
//            return instances
//        }
//        return []
//    }
    
//    // 38% Better
//    static func getRelationship(leftID: SQLiteModelID) -> [RightModel] {
//        if let result = try? self.fetch(self.table.filter(RelationshipColumns.LeftID == leftID)) {
//            
//            let rightIDs = result.map {$0.get(RelationshipColumns.RightID)}
//            let cachedIDsSplit = Meta.queryCachedInstanceIDsFor(RightModel.self, hashes: rightIDs)
//            var instances: [RightModel] = cachedIDsSplit.0.map { RightModel(localID: $0) }
//            if cachedIDsSplit.1.count > 0 {
//                let query = RightModel.table.filter(rightIDs.contains(RightModel.localIDExpression))
//                guard let fetchedInstances = try? RightModel.fetch(query) else {
//                    return instances
//                }
//                instances += fetchedInstances
//            }
//            return instances
//        }
//        return []
//    }
 
// 92% better using caching
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
    
    static func setRelationship(left: LeftModel, right: [RightModel]) -> [SQLiteModelID] {
        let _ = try? self.delete(self.table.filter(RelationshipColumns.LeftID == left.localID))
        var ids = [SQLiteModelID]()
        
        for rightModel in right {
            let setters = [
                RelationshipColumns.LeftID <- left.localID,
                RelationshipColumns.RightID <- rightModel.localID,
            ]            
            let id = try! self.new(setters).localID // JHTODO
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
