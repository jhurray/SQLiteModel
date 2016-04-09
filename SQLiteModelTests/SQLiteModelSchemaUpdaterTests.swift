//
//  SQLiteModelSchemaUpdaterTests.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 4/7/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import XCTest
import SQLite
@testable import SQLiteModel

protocol Car {
    var make: String {get set}
    var model: String {get set}
    var year: Int? {get set}
}

struct CarModel : SQLiteModel, Car {
    
    static let Make = Expression<String>("make")
    static let Model = Expression<String>("model")
    static let Year = Expression<Int?>("year")
    
    // MARK: SQLiteModel
    
    var localID: Int64 = -1
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(CarModel.Make)
    }
    
    static func alterSchema(schemaUpdater: SchemaUpdater) {
        schemaUpdater.alterTable("0.1") { (table: Table) -> [AlterationStatement]! in
            return [
                table.addColumn(CarModel.Model, defaultValue: "Firebird"),
                table.addColumn(CarModel.Year, check: (1990...2017).contains(CarModel.Year))
            ]
        }
    }
    
    // MARK: Car
    
    var make: String {
        get {
            return self => CarModel.Make
        }
        set {
            self <| CarModel.Make |> newValue
        }
    }
    
    var model: String {
        get {
            return self => CarModel.Model
        }
        set {
            self <| CarModel.Model |> newValue
        }
    }
    
    var year: Int? {
        get {
            return self => CarModel.Year
        }
        set {
            self <| CarModel.Year |> newValue
        }
    }
}


class SQLiteModelSchemaUpdaterTests: SQLiteModelTestCase {

    var pontiac: CarModel?
    
    override func setUp() {
        super.setUp()
        let _ = try? CarModel.createTable()
        
        self.pontiac = try? CarModel.new([
                CarModel.Make <- "Pontiac",
                CarModel.Year <- 1995,
            ])
    }
    
    override func tearDown() {
        let _ = try? CarModel.dropTable()
        super.tearDown()
    }

    func testAlterTableSchema() {
        XCTAssertEqual(self.pontiac?.make, "Pontiac")
        XCTAssertEqual(self.pontiac?.model, "Firebird")
        XCTAssertEqual(self.pontiac?.year, 1995)
    }

}
