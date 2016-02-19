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
    var name = ""
    var id: Int64? = -1
    //var ownerID: Int64?
    var owner: Person?
    
    var localID: Int64? {
        get {return id}
        set {id = newValue}
    }
    
    struct Columns {
        static let name = Expression<String>("d_name")
        //static let ownerID = Expression<Int64?>("ownerID")
        static let owner = Relationship<Person?>("owner")
    }
    
    mutating func mapSQLite(inout context: SQLiteConvertibleContext) throws {
        try context.map(value: &self.name, expression: Columns.name)
        //try context.map(value: &self.ownerID, expression: Columns.ownerID)
        try context.map(value: &owner, relationship: Dog.Columns.owner)
    }
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(Columns.name)
        //tableBuilder.column(Columns.ownerID)
        //tableBuilder.foreignKey(Columns.ownerID, references: Person.table, Person.localIDExpression)
        tableBuilder.relationship(Columns.owner, references: Person.self)
    }
    
    static func instance() -> Dog {
        return Dog()
    }
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
    
    func testJoin() {
        sqlmdl_runTest("Test Join") { () -> Void in
            
            var owner = Person(id: nil, name: "Jeff", age: 23)
            try owner.save()
            var max = Dog(name: "Max", id: nil, owner: owner)
            var agnes = Dog(name: "Agnes", id: nil, owner: owner)
            //var max = Dog(name: "Max", id: nil, ownerID:owner.id)
            //var agnes = Dog(name: "Agnes", id: nil, ownerID: owner.id)
            try max.save()
            try agnes.save()
            
            //let q = Dog.query.join(Person.table, on: Person.table[Person.localIDExpression] == Dog.table[Dog.Columns.ownerID])
            let dogs = try Dog.fetchAll()
            print(dogs)
            
        }
    }

}
