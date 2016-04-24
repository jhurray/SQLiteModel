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
    
    func database() throws -> Connection {
        let path = try self.path()
        let db = try Connection(path)
        db.trace {LogManager.log("SQLiteModel: \n\($0)\n")}
        db.busyTimeout = 5
        return db
    }
    
    private func path() throws -> Connection.Location {
        
        switch self {
        case .Disk:
            #if os(iOS)
                let path = NSSearchPathForDirectoriesInDomains(
                    .DocumentDirectory, .UserDomainMask, true
                    ).first!
                return Connection.Location.URI("\(path)/db.sqlite3")
            #elseif os(OSX)
                let path = NSSearchPathForDirectoriesInDomains(
                    .ApplicationSupportDirectory, .UserDomainMask, true
                    ).first! + NSBundle.mainBundle().bundleIdentifier!
                
                // create parent directory iff it doesn’t exist
                try NSFileManager.defaultManager().createDirectoryAtPath(
                    path, withIntermediateDirectories: true, attributes: nil
                )
                return Connection.Location.URI("\(path)/db.sqlite3")
            #elseif os(tvOS)
                let path = NSSearchPathForDirectoriesInDomains(
                    .DocumentDirectory, .UserDomainMask, true
                    ).first!
                return Connection.Location.URI("\(path)/db.sqlite3")
            #endif
        case .TemporaryDisk:
            return Connection.Location.Temporary
        case .InMemory:
            return Connection.Location.InMemory
        }
    }
}

public class SQLiteDatabaseManager {
    
    private static let _sharedInstance = SQLiteDatabaseManager()
    
    private var database: Connection?
    private var type: DatabaseType = DatabaseType.Disk
    
    internal static func connection() throws -> Connection {
        if let db = self._sharedInstance.database {
            return db
        }
        else {
            self._sharedInstance.database = try self._sharedInstance.type.database()
            return self._sharedInstance.database!
        }
    }
    
    public static func setDataBaseType(type: DatabaseType) {
        guard self._sharedInstance.type != type else {
            return
        }
        self._sharedInstance.type = type
        self._sharedInstance.database = nil
    }
}

