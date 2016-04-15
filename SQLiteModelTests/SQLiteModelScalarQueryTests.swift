//
//  SQLiteModelScalarQueryTests.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 4/15/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import XCTest
import SQLite
@testable import SQLiteModel

struct Human: SQLiteModel {
    var localID: Int64 = -1
    
    static let Age = Expression<Int>("age")
    static let Weight = Expression<Double>("weight")
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(Age)
        tableBuilder.column(Weight)
    }
}

class SQLiteModelScalarQueryTests: SQLiteModelTestCase {

    var humans: [Human] = []
    
    override func setUp() {
        super.setUp()
        try! Human.createTable()
        for i in 0...50 {
            let human = try! Human.new([Human.Age <- i, Human.Weight <- Double(i) * 3.0])
            humans.append(human)
        }
    }
    
    override func tearDown() {
        try! Human.dropTable()
        super.tearDown()
    }
    
    func testCount() {
        let count = try! Human.count()
        XCTAssertEqual(count, humans.count)
    }
}
