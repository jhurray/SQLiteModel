//
//  SQLiteModelTestCase.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 12/28/15.
//  Copyright © 2015 jhurray. All rights reserved.
//

import XCTest

internal class SQLiteModelTestCase: XCTestCase {

    internal enum SQLiteModelTestError : ErrorType {
        case Failure(message: String)
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
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
