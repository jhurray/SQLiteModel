//
//  SQLiteModelTests.swift
//  SQLiteModelTests
//
//  Created by Jeff Hurray on 12/24/15.
//  Copyright © 2015 jhurray. All rights reserved.
//

import XCTest
import SQLite
@testable import SQLiteModel

struct Person : SQLiteModel {
    
    var id: Int64?
    var name: String
    var age: Int
    
    static let nameExp = Expression<String>("name")
    static let ageExp = Expression<Int>("age")
    
    var localID: Int64? {
        get {return id}
        set {id = newValue}
    }
    
    static func buildTable(tableBuilder: TableBuilder) -> Void {
        tableBuilder.column(nameExp)
        tableBuilder.column(ageExp)
    }
    
    static func instance() -> Person {
        return Person(id: nil, name: "-1", age: -1)
    }
    
    mutating func mapSQLite(inout context: SQLiteConvertibleContext) throws {
        try context.map(value: &name, expression: Person.nameExp)
        try context.map(value: &age, expression: Person.ageExp)
    }
}

class SQLiteModelTests: SQLiteModelTestCase {
    
    var person: Person = Person(id: nil, name: "Jeff", age: 23)
    
    override func setUp() {
        super.setUp()
    }
    
    func testCreateTable() {
        self.sqlmdl_runTest("Create Person Table") { () -> Void in
            try Person.createTable()
        }
    }
    
    func testDropTable() {
        self.sqlmdl_runTest("Drop Person Table") { () -> Void in
            try Person.dropTable()
        }
    }
    
    func testSave() {
        self.sqlmdl_runTest("Insert Person (Jeff, 23)") { () -> Void in
            try Person.createTable()
            try self.person.save()
            
            guard let id = self.person.localID else {
                throw SQLiteModelTestError.Failure(message: "localID is nil after insert")
            }
            guard let createdAt = self.person.localCreatedAt else {
                throw SQLiteModelTestError.Failure(message: "localCreatedAt is nil after insert")
            }
            guard let updatedAt = self.person.localUpdatedAt else {
                throw SQLiteModelTestError.Failure(message: "localUpdatedAt is nil after insert")
            }
            
            self.person.name = "Fredrick"
            self.person.age = 12
            try self.person.save()
            
            guard let id_AfterSave = self.person.localID else {
                throw SQLiteModelTestError.Failure(message: "localID is nil after update")
            }
            guard let createdAt_AfterSave = self.person.localCreatedAt else {
                throw SQLiteModelTestError.Failure(message: "localCreatedAt is nil after update")
            }
            guard let updatedAt_AfterSave = self.person.localUpdatedAt else {
                throw SQLiteModelTestError.Failure(message: "localUpdatedAt is nil after update")
            }
            
            XCTAssertEqual(id, id_AfterSave)
            XCTAssertEqual(createdAt, createdAt_AfterSave)
            XCTAssertNotEqual(updatedAt, updatedAt_AfterSave)
            
        }
    }
    
    func testFetchAndDelete() {
        sqlmdl_runTest("Fetch Person") { () -> Void in
            try Person.createTable()
            try Person.deleteAll()
            for i in(1...10) {
                let name = "Number-\(i)"
                let age = i + 15
                var p = Person(id: nil, name: name, age: age)
                try p.save()
            }
            
            let query = Person.query.filter(Person.ageExp >= 21)
            
            var people = try Person.fetchAll()
            XCTAssertEqual(people.count, 10)
    
            
            let filteredPeople = try Person.fetch(query)
            XCTAssertEqual(filteredPeople.count, 5)
            
            try Person.delete(query)
            people = try Person.fetchAll()
            XCTAssertEqual(people.count, 5)
            
            XCTAssertEqual(filteredPeople.count, people.count)
            
            try Person.deleteAll()
            people = try Person.fetchAll()
            XCTAssertEqual(people.count, 0)
            
        }
    }
    
    func testAllBasicFunctionality() {
        sqlmdl_runTest("Basic Functionality Smoke Test") { () -> Void in
            
            let assertPersonEqual: ([Person], [Person]) -> Bool = { people1, people2 in
                let countEqual = (people1.count == people2.count)
                let first1 = people1.first!
                let first2 = people1.first!
                let nameEqual = first1.name == first2.name
                let ageEqual = first1.age == first2.age
                
                return countEqual && nameEqual && ageEqual
            }
                        
            // Test Drop / Create
            
            try Person.dropTable()
            try Person.createTable()
            
            
            // Test Insert
            
            var john = Person(id: nil, name: "John", age: 42)
            try john.save()
            var bob = Person(id: nil, name: "Bob", age: 89)
            try bob.save()
            var chris = Person(id: nil, name: "Chris", age: 26)
            try chris.save()
            var sally = Person(id: nil, name: "Sally", age: 90)
            try sally.save()
            var alice = Person(id: nil, name: "Alice", age: 21)
            try alice.save()
            var kid1 = Person(id: nil, name: "Kid1", age: 6)
            try kid1.save()
            var kid2 = Person(id: nil, name: "Kid2", age: 8)
            try kid2.save()
            var kid3 = Person(id: nil, name: "Kid3", age: 10)
            try kid3.save()
            let people = [john, bob, chris, sally, alice, kid1, kid2, kid3]
            
            // Test Fetching
            
            let allPeople = try Person.fetchAll()
            let allPeople2 = try Person.fetch(Person.query)
            XCTAssertEqual(allPeople.count, people.count)
            XCTAssertEqual(allPeople.count, allPeople2.count)
            
            
            let kidsAgeQuery = Person.query.filter(Person.ageExp < 18)
            let kidsNameQuery = Person.query.filter(Person.nameExp.like("Kid%"))
            
            let geezerAgeQuery = Person.query.filter(Person.ageExp > 65)
            let geezerAgeRangeQuery = Person.query.filter((65...150).contains(Person.ageExp))
            let geezerNameQuery = Person.query.filter(Person.nameExp.lowercaseString == "sally" || Person.nameExp == "Bob")
            
            let kidsByAge = try Person.fetch(kidsAgeQuery)
            let kidsByName = try Person.fetch(kidsNameQuery)
            XCTAssertTrue(assertPersonEqual(kidsByAge, kidsByName))
            
            let geezersByAge = try Person.fetch(geezerAgeQuery)
            let geezersByAgeRange = try Person.fetch(geezerAgeRangeQuery)
            let geezersByName = try Person.fetch(geezerNameQuery)
            XCTAssertTrue(assertPersonEqual(geezersByAge, geezersByAgeRange))
            XCTAssertTrue(assertPersonEqual(geezersByAgeRange, geezersByName))
            
            
            // Test Deletion
            
            try Person.delete(kidsNameQuery)
            let peopleAfterDeletingKids = try Person.fetchAll()
            XCTAssertEqual(peopleAfterDeletingKids.count, allPeople.count - kidsByName.count)
            
            // Test Static Update
            
            try Person.update(geezerAgeQuery, values: Person.ageExp -= 35)
            let geezersAfterAgeUpdate = try Person.fetch(geezerAgeQuery)
            let geezersByNameAfterUpdate = try Person.fetch(geezerNameQuery)
            XCTAssertNotEqual(geezersByNameAfterUpdate.count, geezersAfterAgeUpdate.count)
            XCTAssertEqual(geezersAfterAgeUpdate.count, 0)
            
            // Test Instance Update
            
            john.age = 108
            john.name = "Old John"
            try john.save()
            let geezersAfterAgeUpdate_and_afterJohnUpdate = try Person.fetch(geezerAgeQuery)
            XCTAssertEqual(geezersAfterAgeUpdate_and_afterJohnUpdate.count, 1)
            XCTAssertNotEqual(geezersAfterAgeUpdate_and_afterJohnUpdate.count, geezersAfterAgeUpdate.count)
            let oldJohn = geezersAfterAgeUpdate_and_afterJohnUpdate.first!
            XCTAssertEqual(oldJohn.name, john.name)
            XCTAssertEqual(oldJohn.age, john.age)
            
            // Test Instance Delete
            
            try john.delete()
            let geezersAfterAgeUpdate_and_afterJohnUpdate_and_afterJohnDead = try Person.fetch(geezerAgeQuery)
            XCTAssertEqual(geezersAfterAgeUpdate_and_afterJohnUpdate_and_afterJohnDead.count, 0)
            
            try chris.delete()
            let allPeopleAfterKidsAndJohnAndChrisDeleted = try Person.fetchAll()
            XCTAssertEqual(allPeople.count - kidsByName.count - 2, allPeopleAfterKidsAndJohnAndChrisDeleted.count)
            
        }
    }
}
