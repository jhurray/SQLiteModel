//
//  SQLiteModelRelationshipTest.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 1/5/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import XCTest
import SQLite
@testable import SQLiteModel

struct Dog : SQLiteModel {

    var localID: Int64 = -1
    
    struct Columns {
        static let name = Expression<String>("name")
        // dogs dont have to have an owner...
        static let owner = Relationship<Person?>("owner")
        // but they have a best friend :-)
        static let bestFriend = Relationship<Person?>("best_friend", unique: true)
    }
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(Columns.name)
        tableBuilder.relationship(Columns.owner, mappedFrom: self)
        tableBuilder.relationship(Columns.bestFriend, mappedFrom: self)
    }
}

class SQLiteModelSingularRelationshipTest: SQLiteModelTestCase {

    override func setUp() {
        super.setUp()
        do {
            try Dog.dropTable()
            try Dog.createTable()
        }
        catch {
            XCTFail("\(self.dynamicType) Set Up Faliure: Could not create table.")
        }
    }
    
    override func tearDown() {
        super.tearDown()
        do {
            try Dog.dropTable()
        }
        catch {
            XCTFail("\(self.dynamicType) Tear Down Faliure: Could not drop table.")
        }
    }
    
    func testOneToOneRelationship() {
        sqlmdl_runTest("Test One to One Relationship") { () -> Void in
            
            let Jeff = try Person(name: "Jeff", age: 23)
            var Max = try Dog.new([Dog.Columns.name <- "Max"])
            Max <| Dog.Columns.owner |> Jeff
            guard let owner = Max => Dog.Columns.owner else {
                XCTAssert(false)
                return
            }
            
            XCTAssertEqual(owner.localID, Jeff.localID)
            XCTAssertEqual(owner => Person.Columns.nameExp, Jeff => Person.Columns.nameExp)
            XCTAssertEqual(owner => Person.Columns.ageExp, Jeff => Person.Columns.ageExp)
            
            let Chris = try Person(name: "Chris", age: 22)
            Max <| Dog.Columns.owner |> Chris
            let newOwner = (Max => Dog.Columns.owner)!
            
            XCTAssertEqual(newOwner.localID, Chris.localID)
            XCTAssertEqual(newOwner => Person.Columns.nameExp, Chris => Person.Columns.nameExp)
            XCTAssertEqual(newOwner => Person.Columns.ageExp, Chris => Person.Columns.ageExp)
            
            try Max.save()
            let newOwner_afterSave = (Max => Dog.Columns.owner)!
            
            XCTAssertEqual(newOwner_afterSave.localID, Chris.localID)
            XCTAssertEqual(newOwner_afterSave => Person.Columns.nameExp, Chris => Person.Columns.nameExp)
            XCTAssertEqual(newOwner_afterSave => Person.Columns.ageExp, Chris => Person.Columns.ageExp)
            
        }
    }
    
    func testOneToOneRelationshipCascadeDelete() {
        sqlmdl_runTest("Test One to One Relationship Cascade Delete") { () -> Void in
            
            let Jeff = try Person(name: "Jeff", age: 23)
            let Max = try Dog.new([Dog.Columns.name <- "Max"])
            Max <| Dog.Columns.owner |> Jeff
            guard let owner = Max => Dog.Columns.owner else {
                XCTAssert(false)
                return
            }
            
            XCTAssertEqual(owner.localID, Jeff.localID)
            XCTAssertEqual(owner => Person.Columns.nameExp, Jeff => Person.Columns.nameExp)
            XCTAssertEqual(owner => Person.Columns.ageExp, Jeff => Person.Columns.ageExp)
            
            try Jeff.delete()
            let newOwner = Max => Dog.Columns.owner
            XCTAssertNil(newOwner)
        }
    }
    
    func testOneToOneRelationshipUniqueRelationsionship() {
        sqlmdl_runTest("Test One to One Relationship Unique Relationship") { () -> Void in
            
            let Jeff = try Person(name: "Jeff", age: 23)
            let Max = try Dog.new([Dog.Columns.name <- "Max"])
            let Agnes = try Dog.new([Dog.Columns.name <- "Agnes"])
            Max <| Dog.Columns.owner |> Jeff
            Max <| Dog.Columns.bestFriend |> Jeff
            Agnes <| Dog.Columns.owner |> Jeff
            
            let maxesOwner = (Max => Dog.Columns.owner)!
            let maxesBestFriend = (Max => Dog.Columns.bestFriend)!
            let agnesesOwner = (Agnes => Dog.Columns.owner)!
            
            XCTAssertEqual(maxesOwner.localID, Jeff.localID)
            XCTAssertEqual(maxesOwner => Person.Columns.nameExp, Jeff => Person.Columns.nameExp)
            XCTAssertEqual(maxesOwner => Person.Columns.ageExp, Jeff => Person.Columns.ageExp)
            
            XCTAssertEqual(maxesOwner.localID, agnesesOwner.localID)
            XCTAssertEqual(maxesOwner => Person.Columns.nameExp, agnesesOwner => Person.Columns.nameExp)
            XCTAssertEqual(maxesOwner => Person.Columns.ageExp, agnesesOwner => Person.Columns.ageExp)
            
            XCTAssertEqual(maxesBestFriend.localID, Jeff.localID)
            XCTAssertEqual(maxesBestFriend => Person.Columns.nameExp, Jeff => Person.Columns.nameExp)
            XCTAssertEqual(maxesBestFriend => Person.Columns.ageExp, Jeff => Person.Columns.ageExp)
            
            Agnes <| Dog.Columns.bestFriend |> Jeff
            let maxesNewBestFriend = Max => Dog.Columns.bestFriend
            let agnesesBestFreind = (Agnes => Dog.Columns.bestFriend)!
            
            XCTAssertNil(maxesNewBestFriend)
            XCTAssertEqual(agnesesBestFreind.localID, Jeff.localID)
            XCTAssertEqual(agnesesBestFreind => Person.Columns.nameExp, Jeff => Person.Columns.nameExp)
            XCTAssertEqual(agnesesBestFreind => Person.Columns.ageExp, Jeff => Person.Columns.ageExp)
        }
    }

}
