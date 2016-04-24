//: Playground - noun: a place where people can play

import UIKit
import SQLiteModel
import SQLite

struct Person: SQLiteModel {
    
    var localID: SQLiteModelID = -1
    
    static let Name = Expression<String>("name")
    static let Age = Expression<Int>("age")
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(Name)
        tableBuilder.column(Age)
    }
}

do {
    
    try Person.createTable()
    
    let jack = try Person.new([
            Person.Age <- 10,
            Person.Name <- "Jack"
        ])
    
    let jill = try Person.new([
        Person.Age <- 12,
        Person.Name <- "Jill"
        ])
    
    let peopleWhoRanUpTheHill = try Person.fetchAll()
    
    let jackQuery = Person.query.filter(Person.Name == "Jack")
    let personWhoBrokeHisCrown = try Person.fetch(jackQuery)
    
    try Person.updateAll([Person.Age += 10])
    let grownups = try Person.fetchAll()
    
    
    try jill.delete()
    let lastManOnEarth = try Person.fetchAll()
    
    try Person.deleteAll()
    try Person.dropTable()
    
}
catch let error {
    print("SQLiteModel Error: \(error).")
}


