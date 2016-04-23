//
//  SQLiteModelThreadSafetyTests.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 4/23/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import XCTest
import SQLite
@testable import SQLiteModel

struct ModelA: SQLiteModel {
    
    var localID: SQLiteModelID = -1
    
    static let Number = Expression<Float>("number")
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(Number, defaultValue: 0.0)
    }
    
    var number: Float {
        set {
            self <| ModelA.Number |> newValue
        }
        get {
            return self => ModelA.Number
        }
    }
}

final class ModelB: SQLiteModel {
    
    var localID: SQLiteModelID = -1
    required init() {}
    
    static let Text = Expression<String>("text")
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(Text, defaultValue: "default")
    }
    
    var text: String {
        set {
            self <| ModelB.Text |> newValue
        }
        get {
            return self => ModelB.Text
        }
    }
}

class SQLiteModelThreadSafetyTests: SQLiteModelTestCase {

    var modelA: ModelA?
    var modelB: ModelB?
    
    let queue1 = dispatch_queue_create("background.serial.1", DISPATCH_QUEUE_SERIAL)
    let queue2 = dispatch_queue_create("background.concurrent", DISPATCH_QUEUE_CONCURRENT)
    let queue3 = dispatch_queue_create("background.serial.2", DISPATCH_QUEUE_SERIAL)
    
    typealias End = () -> ()
    func performAsyncTest(title: String, testBlock: (End) -> Void) {
        let expectation = expectationWithDescription("Queue Test: \(title)")
        
        testBlock {
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(10.0) { (error: NSError?) -> Void in
            if let error = error {
                XCTFail("Error: \(title) queue test timed out with error: \(error)")
            }
            else {
                print("Success: Queue test \"\(title)\"")
            }
        }
    }
    
    override func setUp() {
        try! ModelA.createTable()
        try! ModelB.createTable()
        modelA = try? ModelA.new([])
        modelB = try? ModelB.new([])
    }
    
    override func tearDown() {
        try! ModelA.dropTable()
        try! ModelB.dropTable()
    }
    
    func testDefaultValues() {
        XCTAssertEqual(modelA!.number, 0)
        XCTAssertEqual(modelB!.text, "default")
    }
    
    func testSingleSerialQueues() {
        performAsyncTest("Serial Queues") { end in
            let group = dispatch_group_create()
            
            dispatch_group_enter(group)
            dispatch_async(self.queue1, {
                self.modelA!.number = 3
                self.modelB!.text = "fizz"
                dispatch_group_leave(group)
            })
            
            dispatch_group_enter(group)
            dispatch_async(self.queue1, {
                self.modelA!.number = 5
                self.modelB!.text = "buzz"
                dispatch_group_leave(group)
            })
            
            dispatch_group_notify(group, dispatch_get_main_queue(), {
                XCTAssertEqual(self.modelA!.number, 5)
                XCTAssertEqual(self.modelB!.text, "buzz")
                end()
            })
        }
    }
    
    func testMultipleSerialQueues() {
        performAsyncTest("Serial Queues") { end in
            let group = dispatch_group_create()
            
            dispatch_group_enter(group)
            dispatch_async(self.queue1, {
                ModelA.transaction ({
                    if self.modelA!.number == 0 {
                        self.modelA!.number = 3
                    }
                    else {
                        self.modelA!.number = 5
                    }
                })
                ModelB.transaction ({
                    if self.modelB!.text == "default" {
                        self.modelB!.text = "fizz"
                    }
                    else {
                        self.modelB!.text = "fizzbuzz"
                    }
                })
                dispatch_group_leave(group)
            })
            
            dispatch_group_enter(group)
            dispatch_async(self.queue3, {
                ModelA.transaction ({
                    if self.modelA!.number == 0 {
                        self.modelA!.number = 3
                    }
                    else {
                        self.modelA!.number = 5
                    }
                })
                ModelB.transaction ({
                    if self.modelB!.text == "default" {
                        self.modelB!.text = "fizz"
                    }
                    else {
                        self.modelB!.text = "fizzbuzz"
                    }
                })
                dispatch_group_leave(group)
            })
            
            dispatch_group_notify(group, dispatch_get_main_queue(), {
                XCTAssertEqual(self.modelA!.number, 5)
                XCTAssertEqual(self.modelB!.text, "fizzbuzz")
                end()
            })
        }
    }
    
    func testConcurrentQueues() {
        performAsyncTest("Concurrent Queues") { end in
            let group = dispatch_group_create()
            
            dispatch_group_enter(group)
            dispatch_group_enter(group)
            
            dispatch_async(self.queue2, {
                ModelA.transaction ({
                    if self.modelA!.number == 0 {
                        self.modelA!.number = 3
                    }
                    else {
                        self.modelA!.number = 5
                    }
                })
                ModelB.transaction ({
                    if self.modelB!.text == "default" {
                        self.modelB!.text = "fizz"
                    }
                    else {
                        self.modelB!.text = "fizzbuzz"
                    }
                })
                dispatch_group_leave(group)
            })
            
            dispatch_async(self.queue2, {
                ModelA.transaction ({
                    if self.modelA!.number == 0 {
                        self.modelA!.number = 3
                    }
                    else {
                        self.modelA!.number = 5
                    }
                })
                ModelB.transaction ({
                    if self.modelB!.text == "default" {
                        self.modelB!.text = "fizz"
                    }
                    else {
                        self.modelB!.text = "fizzbuzz"
                    }
                })
                dispatch_group_leave(group)
            })
            
            dispatch_group_notify(group, dispatch_get_main_queue(), {
                XCTAssertEqual(self.modelA!.number, 5)
                XCTAssertEqual(self.modelB!.text, "fizzbuzz")
                end()
            })
        }
    }
    
}
