//
//  SQLiteModelAsyncTest.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 4/10/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import XCTest
import SQLite
@testable import SQLiteModel

struct Node: SQLiteModel {
    
    var localID: Int64 = -1
    
    static let Name = Expression<String>("name")
    static let Parent = Relationship<Node>("parent")
    static let Children = Relationship<[Node]>("children")
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(Name)
        tableBuilder.relationship(Parent, mappedFrom: self)
        tableBuilder.relationship(Children, mappedFrom: self)
    }
}

class SQLiteModelAsyncTest: SQLiteModelTestCase {

    var nodes: [Node] = []
    var n0: Node?
    var n1: Node?
    
    typealias End = () -> ()
    func performAsyncTest(title: String, testBlock: (End) -> Void) {
        
        let expectation = expectationWithDescription("Async Test: \(title)")
        
        //LogManager.startLogging()
        Node.createTableInBackground({ (error: SQLiteModelError?) -> Void in
            guard error == nil else {
                fatalError("Failed to create Table in background: \(error)")
            }
            Node.newInBackground([Node.Name <- "my first node"]) { (node: Node?, error: SQLiteModelError?) -> Void in
                if let node = node {
                    self.n0 = node
                    self.nodes.append(node)
                }
                else {
                    fatalError("Error: \(error)")
                }
                
                for index in 1...10 {
                    let node = try! Node.new([Node.Name <- "node.\(index)"], relationshipSetters: [Node.Children <- self.nodes])
                    self.nodes.append(node)
                }
                
                testBlock {
                    Node.dropTableInBackground { (error: SQLiteModelError?) -> Void in
                        if let error = error {
                            fatalError("Failed to drop table in background: \(error)")
                        }
                        LogManager.stopLogging()
                        expectation.fulfill()
                    }
                }
            }
        })
        
        waitForExpectationsWithTimeout(5.0) { (error: NSError?) -> Void in
            if let error = error {
                XCTFail("Error: \(title) test timed out with error: \(error)")
            }
            else {
                print("Success: Async test \"\(title)\"")
            }
        }
        
    }
    
    override func setUp() {
        //super.setUp()
    }
    
    override func tearDown() {
        //super.tearDown()
    }

    func testNode0() {
        performAsyncTest("Node 0") { end in
            XCTAssert(self.n0 != nil)
            end()
        }
    }

    func testNodeCount() {
        performAsyncTest("Node Count") { end in
            XCTAssert(self.nodes.count == 11)
            end()
        }
    }
    
    func testNodeGetAsync() {
        performAsyncTest("Node Count") { end in
            guard let node10 = self.nodes.last else {
                XCTFail("Could not get last node")
                end()
                return
            }
            node10 ~* Node.Children ~* { value in
                XCTAssert(value.count == 10)
                end()
            }
        }
    }
}
