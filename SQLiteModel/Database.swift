//
//  SQLiteDatabaseManager.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 12/26/15.
//  Copyright © 2015 jhurray. All rights reserved.
//

import Foundation
import SQLite

public enum DatabaseType {
    case Disk
    case TemporaryDisk
    case InMemory
    
    func database(name: String = "db") throws -> Connection {
        let path = try self.path(name)
        let db = try Connection(path)
        db.trace {LogManager.log("SQLiteModel: \n\($0)\n")}
        db.busyTimeout = 5
        return db
    }
    
    private func path(name: String) throws -> Connection.Location {
        
        switch self {
        case .Disk:
            #if os(iOS)
                let path = NSSearchPathForDirectoriesInDomains(
                    .DocumentDirectory, .UserDomainMask, true
                    ).first!
                return Connection.Location.URI("\(path)/\(name).sqlite3")
            #elseif os(OSX)
                let path = NSSearchPathForDirectoriesInDomains(
                    .ApplicationSupportDirectory, .UserDomainMask, true
                    ).first! + NSBundle.mainBundle().bundleIdentifier!
                
                // create parent directory iff it doesn’t exist
                try NSFileManager.defaultManager().createDirectoryAtPath(
                    path, withIntermediateDirectories: true, attributes: nil
                )
                return Connection.Location.URI("\(path)/\(name).sqlite3")
            #elseif os(tvOS)
                let path = NSSearchPathForDirectoriesInDomains(
                    .DocumentDirectory, .UserDomainMask, true
                    ).first!
                return Connection.Location.URI("\(path)/\(name).sqlite3")
            #endif
        case .TemporaryDisk:
            return Connection.Location.Temporary
        case .InMemory:
            return Connection.Location.InMemory
        }
    }
}

public class Database {
    
    private static var _sharedDatabase: Database? = try? Database()
    
    private let type: DatabaseType
    private let database: Connection
    private(set) var cache: SQLiteModelContextManager = SQLiteModelContextManager()
    
    init(path: String = "db", databaseType: DatabaseType = .Disk) throws {
        self.type = databaseType
        self.database = try type.database(path)
    }
    
    public func connection() -> Connection {
        return self.database
    }
    
    public class func sharedDatabase() throws -> Database {
        guard let sharedDatabase = self._sharedDatabase else {
            self._sharedDatabase = try Database()
            return self._sharedDatabase!
        }
        return sharedDatabase
    }
}
