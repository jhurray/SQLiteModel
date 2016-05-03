//
//  DatabaseTest.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 4/26/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import XCTest
import SQLite
@testable import SQLiteModel

let inMem = Database(databaseType: DatabaseType.InMemory)
let tmpDisk = Database(databaseType: DatabaseType.TemporaryDisk)
let disk = Database(databaseType: DatabaseType.Disk(name: "disk_test"))

struct InMem : SQLiteModel {
    var localID: SQLiteModelID = -1
    
    static var connection: Database {
        return inMem
    }
    
    static let Value = Expression<String>("val")
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(Value, defaultValue: "value")
    }
}

struct TmpDisk : SQLiteModel {
    var localID: SQLiteModelID = -1
    
    static var connection: Database {
        return tmpDisk
    }
    
    static let Value = Expression<String>("val")
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(Value, defaultValue: "value")
    }
}

struct Disk : SQLiteModel {
    var localID: SQLiteModelID = -1
    
    static var connection: Database {
        return disk
    }
    
    static let Value = Expression<String>("val")
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(Value, defaultValue: "value")
    }
}

class DatabaseTest: SQLiteModelTestCase {
    
    override func setUp() {
        
    }
    
    override func tearDown() {
    
    }
    
    func testInMem() {
        do {
            try InMem.createTable()
            let instance = try InMem.new([])
            XCTAssertNotNil(instance)
            try InMem.dropTable()
        }
        catch {
            XCTFail()
        }
    }
    
    func testTmpDisk() {
        do {
            try TmpDisk.createTable()
            let instance = try TmpDisk.new([])
            XCTAssertNotNil(instance)
            try TmpDisk.dropTable()
        }
        catch {
            XCTFail()
        }
    }
    
    func testDisk() {
        do {
            try Disk.createTable()
            let instance = try Disk.new([])
            XCTAssertNotNil(instance)
            try Disk.dropTable()
        }
        catch {
            XCTFail()
        }
    }
}
