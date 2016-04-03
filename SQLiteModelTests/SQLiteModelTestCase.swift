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
    
    var localID: Int64 = -1
    
    init() {}
    init(name: String, age: Int) throws {
        self = try Person.new([
            Person.Columns.nameExp <- name,
            Person.Columns.ageExp <- age
            ])
    }

    struct Columns {
        static let nameExp = Expression<String>("p_name")
        static let ageExp = Expression<Int>("age")
    }
    
    static var initializers: [Setter] {
        return [
            Columns.nameExp <- "unnamed",
            Columns.ageExp <- 0,
        ]
    }
    
    static func buildTable(tableBuilder: TableBuilder) -> Void {
        tableBuilder.column(Columns.nameExp)
        tableBuilder.column(Columns.ageExp)
    }
}

internal class SQLiteModelTestCase: XCTestCase {
    
    internal enum SQLiteModelTestError : ErrorType {
        case Failure(message: String)
    }
    
    override func setUp() {
        super.setUp()
        do {
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
