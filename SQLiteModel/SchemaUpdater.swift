//
//  SchemaUpdater.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 4/5/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import Foundation
import SQLite

public typealias AlterationStatement = String

public class SchemaUpdater {
    
    private let table: Table
    private let tableName: String
    private var queriesByTag: [String : [AlterationStatement]] = [String : [AlterationStatement]]()
    private var invalidTags: [String] = []
    
    internal var alterations: [AlterationStatement] {
        return self.queriesByTag.flatMap{ $0.1 }
    }
    
    internal init(table: Table, tableName: String) {
        self.table = table
        self.tableName = tableName
    }
    
    public func alterTable(tag: String, alterationBlock: (Table) -> [AlterationStatement]!) {
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        guard userDefaults.boolForKey("\(self.tableName).\(tag)") == false else {
            self.invalidTags.append(tag)
            return
        }
        
        let newAlterationStatements = alterationBlock(self.table)
        if let alterationStatements = self.queriesByTag[tag] {
            self.queriesByTag[tag] = alterationStatements + newAlterationStatements
        }
        else {
            self.queriesByTag[tag] = newAlterationStatements
        }
    }
    
    internal func markAlterationsComplete() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        for tag in self.queriesByTag.keys {
            let key = "\(self.tableName).\(tag)"
            userDefaults.setBool(true, forKey: key)
        }
        userDefaults.synchronize()
    }
    
    internal func invalidateAlterations() {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        for tag in self.invalidTags {
            let key = "\(self.tableName).\(tag)"
            userDefaults.setBool(false, forKey: key)
        }
        userDefaults.synchronize()
    }
}
