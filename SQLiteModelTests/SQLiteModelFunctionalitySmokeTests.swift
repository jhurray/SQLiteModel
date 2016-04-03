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

class SQLiteModelFunctionalitySmokeTests: SQLiteModelTestCase {
    
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
    
    func testCreateAndSave() {
        self.sqlmdl_runTest("Insert Person (Jeff, 23)") { () -> Void in

            var person = try Person.new(Person.initializers)
            
            guard person.localID != -1 else {
                throw SQLiteModelTestError.Failure(message: "localID not set during insert")
            }
            guard let createdAt_BeforeSave = person.localCreatedAt else {
                throw SQLiteModelTestError.Failure(message: "localCreatedAt is nil after insert")
            }
            guard let updatedAt_BeforeSave = person.localUpdatedAt else {
                throw SQLiteModelTestError.Failure(message: "localUpdatedAt is nil after insert")
            }
            
            let localID_BeforeSave = person.localID
            let name_BeforeSave = person => Person.Columns.nameExp
            let age_BeforeSave = person => Person.Columns.ageExp
            
            person <| Person.Columns.nameExp |> "Fred"
            person <| Person.Columns.ageExp |> 12
            try person.save()
            
            let localID_AfterSave = person.localID
            let name_AfterSave = person => Person.Columns.nameExp
            let age_AfterSave = person => Person.Columns.ageExp
            
            guard let createdAt_AfterSave = person.localCreatedAt else {
                throw SQLiteModelTestError.Failure(message: "localCreatedAt is nil after update")
            }
            guard let updatedAt_AfterSave = person.localUpdatedAt else {
                throw SQLiteModelTestError.Failure(message: "localUpdatedAt is nil after update")
            }
            
            XCTAssertEqual(localID_BeforeSave, localID_AfterSave)
            XCTAssertEqual(createdAt_BeforeSave, createdAt_AfterSave)
            XCTAssertNotEqual(updatedAt_BeforeSave, updatedAt_AfterSave)
            XCTAssertNotEqual(name_BeforeSave, name_AfterSave)
            XCTAssertNotEqual(age_BeforeSave, age_AfterSave)
            
        }
    }
    
    func testFetchAndDelete() {
        sqlmdl_runTest("Fetch Person") { () -> Void in
            
            try Person.deleteAll()
            for i in(1...10) {
                let name = "Number-\(i)"
                let age = i + 15
                var _ = try Person.new([Person.Columns.nameExp <- name, Person.Columns.ageExp <- age])
            }
            
            let query = Person.query.filter(Person.Columns.ageExp >= 21)
            
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
                let nameEqual = (first1 => Person.Columns.nameExp) == (first2 => Person.Columns.nameExp)
                let ageEqual = (first1 => Person.Columns.ageExp) == (first2 => Person.Columns.ageExp)
                
                return countEqual && nameEqual && ageEqual
            }
                        
            // Test Drop / Create
            
            try Person.dropTable()
            try Person.createTable()
            
            
            // Test Insert
            
            var john = try Person(name: "John", age: 42)
            let bob = try Person(name: "Bob", age: 89)
            let chris = try Person(name: "Chris", age: 26)
            let sally = try Person(name: "Sally", age: 90)
            let alice = try Person(name: "Alice", age: 21)
            let kid1 = try Person(name: "Kid1", age: 6)
            let kid2 = try Person(name: "Kid2", age: 8)
            let kid3 = try Person(name: "Kid3", age: 10)
            let people = [john, bob, chris, sally, alice, kid1, kid2, kid3]
            
            // Test Fetching
            
            let allPeople = try Person.fetchAll()
            let allPeople2 = try Person.fetch(Person.query)
            XCTAssertEqual(allPeople.count, people.count)
            XCTAssertEqual(allPeople.count, allPeople2.count)
            
            
            let kidsAgeQuery = Person.query.filter(Person.Columns.ageExp < 18)
            let kidsNameQuery = Person.query.filter(Person.Columns.nameExp.like("Kid%"))
            
            let geezerAgeQuery = Person.query.filter(Person.Columns.ageExp > 65)
            let geezerAgeRangeQuery = Person.query.filter((65...150).contains(Person.Columns.ageExp))
            let geezerNameQuery = Person.query.filter(Person.Columns.nameExp.lowercaseString == "sally" || Person.Columns.nameExp == "Bob")
            
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
            
            try Person.update(geezerAgeQuery, setters: [Person.Columns.ageExp -= 35])
            let geezersAfterAgeUpdate = try Person.fetch(geezerAgeQuery)
            let geezersByNameAfterUpdate = try Person.fetch(geezerNameQuery)
            XCTAssertNotEqual(geezersByNameAfterUpdate.count, geezersAfterAgeUpdate.count)
            XCTAssertEqual(geezersAfterAgeUpdate.count, 0)
            
            // Test Instance Update
            
            john <| Person.Columns.ageExp |> 108
            john <| Person.Columns.nameExp |> "Old John"
            try john.save()
            let geezersAfterAgeUpdate_and_afterJohnUpdate = try Person.fetch(geezerAgeQuery)
            XCTAssertEqual(geezersAfterAgeUpdate_and_afterJohnUpdate.count, 1)
            XCTAssertNotEqual(geezersAfterAgeUpdate_and_afterJohnUpdate.count, geezersAfterAgeUpdate.count)
            let oldJohn = geezersAfterAgeUpdate_and_afterJohnUpdate.first!
            XCTAssertEqual(oldJohn => Person.Columns.nameExp, john => Person.Columns.nameExp)
            XCTAssertEqual(oldJohn => Person.Columns.ageExp, john => Person.Columns.ageExp)
            
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
