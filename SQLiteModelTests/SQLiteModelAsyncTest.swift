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
    static let Parent = Relationship<Node?>("parent")
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
    let nodeCount = 5
    
    typealias End = () -> ()
    func performAsyncTest(title: String, testBlock: (End) -> Void) {
        
        let expectation = expectationWithDescription("Async Test: \(title)")
        
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
                
                for index in 1...self.nodeCount {
                    let node = try! Node.new([Node.Name <- "node.\(index)"], relationshipSetters: [Node.Children <- self.nodes])
                    if index == 1 {
                        node <| Node.Parent |>  self.n0
                        self.n1 = node
                    }
                    if let lastNode = self.nodes.last {
                        node <| Node.Parent |> lastNode
                    }
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
        
        waitForExpectationsWithTimeout(25.0) { (error: NSError?) -> Void in
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
            XCTAssertNil(self.n0! => Node.Parent)
            XCTAssertEqual(self.n0! => Node.Name, "my first node")
            end()
        }
    }

    func testNodeCount() {
        performAsyncTest("Node Count") { end in
            XCTAssert(self.nodes.count == self.nodeCount + 1)
            end()
        }
    }
    
    func testGetType1Async() {
        performAsyncTest("Get 1") { end in
            guard let lastNode = self.nodes.last else {
                XCTFail("Could not get last node")
                end()
                return
            }
            lastNode ~* Node.Children ~* { value in
                XCTAssert(value.count == self.nodeCount)
                end()
            }
        }
    }
    
    func testGetType2Async() {
        performAsyncTest("Get 2") { end in
            guard let node10 = self.nodes.last else {
                XCTFail("Could not get last node")
                end()
                return
            }
            node10 ~* (Node.Children, { value in
                XCTAssert(value.count == self.nodeCount)
                end()
            })
        }
    }
    
    func testSetAsync() {
        performAsyncTest("Set") { end in
            guard let n0 = self.n0 else {
                XCTFail("Node 0 should not be nil")
                end()
                return
            }
            guard let n1 = self.n1 else {
                XCTFail("Node 1 should not be nil")
                end()
                return
            }
            
            XCTAssertNil(n0 => Node.Parent)
            n0.setInBackground(Node.Parent, value: n1, completion: {
                let shouldBeNode1 = n0 => Node.Parent
                XCTAssertEqual(shouldBeNode1!.localID, n1.localID)
                XCTAssertEqual(shouldBeNode1! => Node.Name, n1 => Node.Name)
                end()
            })
        }
    }
    
    func testSaveAsync() {
        performAsyncTest("Save") { end in
            guard var n0 = self.n0 else {
                XCTFail("Node 0 should not be nil")
                end()
                return
            }
            let newName = "New Node 0 name"
            n0.set(Node.Name, value: newName)
            n0.saveInBackground({ error in
                guard error == nil else {
                    XCTFail("Failed: Error from async save: \(error)")
                    end()
                    return
                }
                XCTAssertEqual(self.n0! => Node.Name , newName)
                end()
            })
        }
    }
    
    func testDeleteInstanceAsync() {
        performAsyncTest("Delete Instance") { end in
            
            guard let n0 = self.n0, let n1 = self.n1 else {
                XCTFail("Node 0 and 1 should not be nil")
                end()
                return
            }
            let shouldBeN0 = n1 => Node.Parent
            XCTAssertEqual(n0.localID, shouldBeN0!.localID)
            n0.deleteInBackground({ error in
                let shouldBeNil = n1 => Node.Parent
                XCTAssertNil(shouldBeNil)
                end()
            })
        }
    }

    func testDeleteAsync() {
        performAsyncTest("Delete Static") { end in
            guard let n0 = self.n0, let n1 = self.n1 else {
                XCTFail("Node 0 and 1 should not be nil")
                end()
                return
            }
            let shouldBeN0 = n1 => Node.Parent
            XCTAssertEqual(n0.localID, shouldBeN0!.localID)
            let query = Node.query.filter(Node.localIDExpression == 1)
            Node.deleteInBackground(query, completion: { error in
                let shouldBeNil = n1 => Node.Parent
                XCTAssertNil(shouldBeNil)
                end()
            })
        }
    }

    func testUpdateAsync() {
        performAsyncTest("Update") { end in
            guard let n0 = self.n0 else {
                XCTFail("Node 0 should not be nil")
                end()
                return
            }
            let newName = "New Node 0 name"
            let query = Node.query.filter(Node.localIDExpression == 1)
            Node.updateInBackground(query, setters: [Node.Name <- newName], relationshipSetters: [Node.Parent <- n0], completion: { error in
                guard error == nil else {
                    XCTFail("Failed: Error from async save: \(error)")
                    end()
                    return
                }
                guard let parent = n0 => Node.Parent else {
                    XCTFail("Failed: Parent should not be nil")
                    end()
                    return
                }
                XCTAssertEqual(parent.localID, n0.localID)
                XCTAssertEqual(n0 => Node.Name , newName)
                XCTAssertEqual(parent => Node.Name, newName)
                XCTAssertEqual(parent.localID, n0.localID)
                end()
            })
        }
    }

    func testFetchAsync() {
        performAsyncTest("Fetch") { end in
            Node.fetchAllInBackground({ (nodes, error) -> Void in
                XCTAssertEqual(nodes.count, self.nodes.count)
                end()
            })
        }
    }
    
    func testCountAsync() {

        performAsyncTest("Count", testBlock: { end in
            Node.countInBackground { (count, error) -> Void in
                XCTAssertNil(error)
                XCTAssertEqual(count, self.nodeCount + 1)
                end()
            }
        })
    }
    
    func testAsyncSmokeTest() {
        performAsyncTest("Delete Static") { end in
            guard let n0 = self.n0, let n1 = self.n1 else {
                XCTFail("Node 0 and 1 should not be nil")
                end()
                return
            }
            let shouldBeN0 = n1 => Node.Parent
            XCTAssertEqual(n0.localID, shouldBeN0!.localID)
            let query = Node.query.filter(Node.localIDExpression == 1)
            Node.deleteInBackground(query, completion: { error in
                Node.fetchAllInBackground({ (newNodes, error) -> Void in
                    XCTAssertEqual(newNodes.count, self.nodeCount)
                    let deleteAllButOne = Node.query.filter((0...self.nodeCount).flatMap({Int64($0)}).contains(Node.localIDExpression))
                    Node.deleteInBackground(deleteAllButOne, completion: { innerError in
                        guard innerError == nil else {
                            XCTFail("Failed: Error from async save: \(innerError)")
                            end()
                            return
                        }
                        Node.fetchInBackground(query, completion: { (emptyNodes, err) -> Void in
                            XCTAssertEqual(emptyNodes.count, 0)
                            Node.fetchAllInBackground({ (shouldBeLastNode, lastError) -> Void in
                                XCTAssertEqual(shouldBeLastNode.count, 1)
                                let n5 = shouldBeLastNode[0]
                                XCTAssertEqual(n5 => Node.Name, "node.\(self.nodeCount)")
                                end()
                            })
                        })
                    })
                })
            })
        }
    }
}
