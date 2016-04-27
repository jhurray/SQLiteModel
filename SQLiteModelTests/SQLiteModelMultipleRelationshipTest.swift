//
//  SQLiteModelMultipleRelationshipTest.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 3/29/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import XCTest
import SQLite
@testable import SQLiteModel

protocol Nameable {
    var name: String {get set}
}

struct Teacher : SQLiteModel, Nameable {
    
    var localID: Int64 = -1
    static let Name = Expression<String>("name")
    static let Students = Relationship<[Student]>("students", unique: true)

    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(Teacher.Name)
        tableBuilder.relationship(Teacher.Students, mappedFrom: self)
    }
    
    var name: String {
        get {
            return self => Teacher.Name
        }
        set(value) {
            self <| Teacher.Name |> value
        }
    }
    
    var students: [Student] {
        get {
            return self => Teacher.Students
        }
        set {
            self <| Teacher.Students |> newValue
        }
    }
    
}

struct Student : SQLiteModel, Nameable {
    
var localID: Int64 = -1
    static let Name = Expression<String>("name")
    static let Teachers = Relationship<[Teacher]>("teacher")
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(Student.Name)
        tableBuilder.relationship(Student.Teachers, mappedFrom: self)
    }
    
    // MARK: Getters / Setters
    
    var name: String {
        get {
            return self => Student.Name
        }
        set(value) {
            self <| Student.Name |> value
        }
    }
    
    var teachers: [Teacher] {
        return self => Student.Teachers
    }
}

class SQLiteModelMultipleRelationshipTest: SQLiteModelTestCase {
    
    var student1: Student?
    var student2: Student?
    var student3: Student?
    var student4: Student?
    var student5: Student?
    
    var teacher1: Teacher?
    var teacher2: Teacher?
    var teacher3: Teacher?
    var teacher4: Teacher?
    var teacher5: Teacher?
    
    var students: [Student]?
    var teachers: [Teacher]?

    override func setUp() {
        super.setUp()
        do {
            try Student.createTable()
            try Teacher.createTable()
            
            student1 = try? Student.new([Student.Name <- "s1"])
            student2 = try? Student.new([Student.Name <- "s2"])
            student3 = try? Student.new([Student.Name <- "s3"])
            student4 = try? Student.new([Student.Name <- "s4"])
            student5 = try? Student.new([Student.Name <- "s5"])
            
            teacher1 = try? Teacher.new([Teacher.Name <- "t1"])
            teacher2 = try? Teacher.new([Teacher.Name <- "t2"])
            teacher3 = try? Teacher.new([Teacher.Name <- "t3"])
            teacher4 = try? Teacher.new([Teacher.Name <- "t4"], relationshipSetters: [Teacher.Students <- [student2!, student3!]])
            teacher5 = try? Teacher.new([Teacher.Name <- "t5"], relationshipSetters: [Teacher.Students <- [student1!]])
            students = try Student.fetchAll()
            teachers = try Teacher.fetchAll()
            
            student1! <| Student.Teachers |> [teacher2!, teacher1!, teacher3!]
        }
        catch {
            XCTFail("\(self.dynamicType) Set Up Faliure: Could not create table.")
        }
    }
    
    override func tearDown() {
        super.setUp()
        do {
            try Teacher.dropTable()
            try Student.dropTable()
        }
        catch {
            XCTFail("\(self.dynamicType) Set Up Faliure: Could not drop table.")
        }
        super.tearDown()
    }
    
    
    func testCount() {
        XCTAssert(students?.count == 5)
        XCTAssert(teachers?.count == 5)
    }
    
    func testTeacherCount() {
        XCTAssertEqual(student1?.teachers.count,  3)
        XCTAssertEqual(student2?.teachers.count,  0)
    }
    
    func testStudentCount() {
        XCTAssertEqual(teacher5?.students.count,  1)
        XCTAssertEqual(teacher3?.students.count,  0)
    }
    
    func testStudentEquality() {
        let shouldBeStudent1 = teacher5?.students.first
        XCTAssert(shouldBeStudent1?.localID == student1?.localID)
        XCTAssert(shouldBeStudent1?.name == student1?.name)
    }
    
    func testGetPerformance() {
        measureBlock {
            for _ in 0...500 {
                let _ = self.student1! => Student.Teachers
            }
        }
    }
    
    func testSetPerformance() {
        var toSet: [Student] = []
        for i in 0...25 {
            let s = try! Student.new([Student.Name <- "s\(i)"])
            toSet.append(s)
        }
        measureBlock {
            for _ in 0...10 {
                self.teacher1! <| Teacher.Students |> toSet
            }
        }
    }
    
    func testTeacherEquality() {
        let shouldBeTeacher1 = student1?.teachers.first
        XCTAssertEqual(shouldBeTeacher1?.localID, teacher1?.localID)
        XCTAssertEqual(shouldBeTeacher1?.name, teacher1?.name)
    }
    
    func testRelationshipBatchUpdate() {
        let _ = try? Student.updateAll(relationshipSetters: [Student.Teachers <- [teacher4!, teacher5!]])
        let newStudents = try? Student.fetchAll()
        for student in newStudents! {
            XCTAssertEqual(student.teachers.count, 2, "Student: \(student.localID)")
        }
    }

    
    func testName() {
        XCTAssert(student1!.name == "s1")
        XCTAssert(teacher1!.name == "t1")
    }
    
    func testInstanceRelationshipCount() {
        XCTAssertEqual(student1?.countForRelationship(Student.Teachers), 3)
    }
    
    func testRelationshipQuery() {
        guard let s1 = student1 else {
            XCTFail()
            return
        }
        let filteredTeachers = s1.get(Student.Teachers, query: Teacher.query.filter(Teacher.Name == "t2"))
        XCTAssertEqual(filteredTeachers.count, 1)
        XCTAssertEqual(filteredTeachers.first?.localID, teacher2?.localID)
    }
    
    func testUniqueMultipleRelationship() {
        guard let t4 = teacher4, let t3 = teacher3 else {
            XCTFail()
            return
        }
        let shouldBeTwoStudents = t4 => Teacher.Students
        XCTAssertEqual(shouldBeTwoStudents.count, 2)
        
        t3 <| Teacher.Students |> [student2!]
        
        let shouldBeOneStudent = t4 => Teacher.Students
        XCTAssertEqual(shouldBeOneStudent.count, 1)
        XCTAssertEqual(shouldBeOneStudent.first!.localID, 3)
        
        let shouldBeStudent2 = t3.students
        XCTAssertEqual(shouldBeStudent2.count, 1)
        XCTAssertEqual(shouldBeStudent2.first?.localID, 2)
        
        t3 <| Teacher.Students |> [student3!]
        
        let shouldBeEmpty = t4 => Teacher.Students
        XCTAssertEqual(shouldBeEmpty.count, 0)
        
        let shouldBeStudent3 = t3.students
        XCTAssertEqual(shouldBeStudent3.count, 1)
        XCTAssertEqual(shouldBeStudent3.first?.localID, 3)
    }
}
