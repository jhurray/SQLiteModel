//
//  SQLiteDatabaseManager.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 12/26/15.
//  Copyright © 2015 jhurray. All rights reserved.
//

import Foundation
import SQLite

enum DatabaseFactory {
    case Disk
    case TemporaryDisk
    case InMemory
    
    func database() throws -> Connection {
        let db = try Connection(self.path())
        db.trace {print("SQLiteModel: \n\($0)\n")}
        return db
    }
    
    private func path() -> Connection.Location {
        
        switch self {
        case .Disk:
            #if os(iOS)
                let path = NSSearchPathForDirectoriesInDomains(
                    .DocumentDirectory, .UserDomainMask, true
                    ).first!
                return Connection.Location.URI("\(path)/db.sqlite3")
            #elseif os(OSX)
                var path = NSSearchPathForDirectoriesInDomains(
                    .ApplicationSupportDirectory, .UserDomainMask, true
                    ).first! + NSBundle.mainBundle().bundleIdentifier!
                
                // create parent directory iff it doesn’t exist
                try NSFileManager.defaultManager().createDirectoryAtPath(
                    path, withIntermediateDirectories: true, attributes: nil
                )
                return Connection.Location.URI("\(path)/db.sqlite3")
            #endif
        case .TemporaryDisk:
            return Connection.Location.Temporary
        case .InMemory:
            return Connection.Location.InMemory
        }
    }
}

class SQLiteDatabaseManager {
    
    private static let _sharedInstance = SQLiteDatabaseManager()
    
    private var database: Connection?
    
    static func connection() throws -> Connection {
        if let db = self._sharedInstance.database {
            return db
        }
        else {
            self._sharedInstance.database = try DatabaseFactory.Disk.database()
            return self._sharedInstance.database!
        }
    }
    
}

