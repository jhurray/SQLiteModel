//: Playground - noun: a place where people can play

import UIKit
import SQLiteModel
import SQLite

struct Person: SQLiteModel {
    
    var localID: SQLiteModelID = -1
    
    static let Name = Expression<String>("name")
    static let Age = Expression<Int>("age")
    static let BFF = Relationship<Person?>("best_friend")
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(Name)
        tableBuilder.column(Age, defaultValue: 0)
        tableBuilder.relationship(BFF, mappedFrom: self)
    }
}

do {
    
    try Person.createTable()
    
    var jack = try Person.new([
            Person.Age <- 10,
            Person.Name <- "Jack"
        ])
    
    let jill = try Person.new([
        Person.Age <- 12,
        Person.Name <- "Jill"
        ])
    
    // Each Model has localID, localCreatedAt, and localUpdatedAt properties
    jack.localID
    jill.localID
    jack.localCreatedAt
    
    // Set age
    jack <| Person.Age |> 11
    // Get age
    let age = jack => Person.Age
    
    // Save an instance
    try jack.save()
    jack.localUpdatedAt
    
    // Simple Fetch
    let peopleWhoRanUpTheHill = try Person.fetchAll()
    
    // Filtered Fetch
    let jackQuery = Person.query.filter(Person.Name == "Jack")
    let personWhoBrokeHisCrown = try Person.fetch(jackQuery).first!
    personWhoBrokeHisCrown => Person.Name
    
    // Update all rows the table
    try Person.updateAll([Person.Age += 10])
    let grownups = try Person.fetchAll()
    jill => Person.Age
    jack => Person.Age
    personWhoBrokeHisCrown => Person.Age
    let ages = grownups.flatMap({ $0 => Person.Age })
    print(ages)
    
    // Relationships set + get
    jack <| Person.BFF |> jill
    let jacksBestFriend = jack => Person.BFF
    jacksBestFriend! => Person.Name
    
    // Delete instance
    try jill.delete()
    let lastManOnEarth = try Person.fetchAll().first!
    lastManOnEarth => Person.Name
    // Relationships will cascade uppon deletion
    jack => Person.BFF
    
    // Delete all rows
    try Person.deleteAll()
    // Drop Table
    try Person.dropTable()
    
}
catch let error {
    print("SQLiteModel Error: \(error).")
}
