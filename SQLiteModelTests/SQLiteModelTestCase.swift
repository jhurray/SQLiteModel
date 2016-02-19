//
//  SQLiteModelTestCase.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 12/28/15.
//  Copyright © 2015 jhurray. All rights reserved.
//

import XCTest
import SQLite
@testable import SQLiteModel

struct Person : SQLiteModel {
    
    var id: Int64?
    var name: String
    var age: Int
    
    static let nameExp = Expression<String>("p_name")
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

internal class SQLiteModelTestCase: XCTestCase {
    
    internal enum SQLiteModelTestError : ErrorType {
        case Failure(message: String)
    }
    
    override func setUp() {
        super.setUp()
        do {
            try Person.dropTable()
            try Person.createTable()
        }
        catch {
            XCTFail("\(self.dynamicType) Set Up Faliure: Could not create table.")
        }
    }
    
    override func tearDown() {
        super.tearDown()
        do {
            try Person.dropTable()
        }
        catch {
            XCTFail("\(self.dynamicType) Tear Down Faliure: Could not drop table.")
        }
    }
    
    internal func sqlmdl_runTest(message: String, test: () throws -> Void) {
        do {
            try test()
        }
        catch SQLiteModelTestError.Failure(message: message){
            XCTFail("\n\nFaliure: \(message)\nDetail: \(message)\n\n")
        }
        catch {
            XCTFail("\n\nFaliure: \(message)\n\n")
        }
        XCTAssertTrue(true, "Success: \(message)")
    }
}
