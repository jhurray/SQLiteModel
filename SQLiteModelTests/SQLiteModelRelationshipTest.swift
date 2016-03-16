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
        static let owner = Relationship<Person?>("owner")
    }
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(Columns.name)
        tableBuilder.relationship(Columns.owner, references: Person.self)
    }
}

extension Person {
    
}

class SQLiteModelRelationshipTest: SQLiteModelTestCase {

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
        sqlmdl_runTest("Test Join") { () -> Void in
            
            let Jeff = try Person(name: "Jeff", age: 23)
            var Max = try Dog.new(Dog.Columns.name <- "Max", Dog.Columns.owner <- Jeff)
            let owner = (Max => Dog.Columns.owner)!
            
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

}
