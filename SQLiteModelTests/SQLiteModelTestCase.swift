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

internal class SQLiteModelTestCase: XCTestCase {
    
    internal enum SQLiteModelTestError : ErrorType {
        case Failure(message: String)
    }
    
    internal func sqlmdl_runTest(message: String, test: () throws -> Void) {
        do {
            try test()
            XCTAssertTrue(true, "Success: \(message)")
        }
        catch SQLiteModelTestError.Failure(message: message){
            XCTFail("\n\nFaliure: \(message)\nDetail: \(message)\n\n")
        }
        catch {
            XCTFail("\n\nFaliure: \(message)\n\n")
        }
    }
}
