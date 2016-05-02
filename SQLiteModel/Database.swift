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
    case Disk(name: String)
    case TemporaryDisk
    case InMemory
    case ReadOnly(name: String)
    
    internal func database() throws -> Connection {
        let path = try self.path()
        print(path)
        let db = try Connection(path)
        db.trace {LogManager.log("SQLiteModel: \n\($0)\n")}
        db.busyTimeout = 5
        db.busyHandler({ tries in
            if tries >= 3 {
                return false
            }
            return true
        })
        return db
    }
    
    private func path() throws -> Connection.Location {
        switch self {
        case .Disk(let name):
            #if os(iOS)
                guard let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first else {
                    throw SQLiteModelError.InitializeDatabase
                }
                return Connection.Location.URI("\(path)/\(name).sqlite3")
            #elseif os(OSX)
                guard let appSupportPath = NSSearchPathForDirectoriesInDomains(
                    .ApplicationSupportDirectory, .UserDomainMask, true
                    ).first else {
                    throw SQLiteModelError.InitializeDatabase
                }
                let bundlePath = NSBundle.mainBundle().bundlePath
                let applicationName = NSFileManager.defaultManager().displayNameAtPath(bundlePath)
                let path = appSupportPath + "/" + applicationName
                try NSFileManager.defaultManager().createDirectoryAtPath(
                    path, withIntermediateDirectories: true, attributes: nil
                )
                return Connection.Location.URI("\(path)/\(name).sqlite3")
            #elseif os(tvOS)
                // Caveat: tvOS does not yet support persistent storage on disk.
                // You must depend on the  relatively low cache wipe frequencyof the OS
                // Or use an InMemory database.
                guard let path = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first else {
                    throw SQLiteModelError.InitializeDatabase
                }
                return Connection.Location.URI("\(path)/\(name).sqlite3")
            #endif
        case .TemporaryDisk:
            return Connection.Location.Temporary
        case .InMemory:
            return Connection.Location.InMemory
        case .ReadOnly(let name):
            guard let path = NSBundle.mainBundle().pathForResource(name, ofType: "sqlite3") else {
                throw SQLiteModelError.InitializeDatabase
            }
            return Connection.Location.URI(path)
        }
    }
}

public class Database {
    
    private(set) static var sharedDatabase: Database = Database()
    
    private let type: DatabaseType
    private let database: Connection
    private(set) var cache: SQLiteModelContextManager = SQLiteModelContextManager()
    
    init(databaseType: DatabaseType = DatabaseType.Disk(name: "sqlite_model_default_database")) {
        self.type = databaseType
        do {
            self.database = try type.database()
        }
        catch let error {
            fatalError("SQLiteModel Fatal Error - Could not initialize database correctly. Error: \(error).")
        }
    }
    
    public func connection() -> Connection {
        return self.database
    }
}
