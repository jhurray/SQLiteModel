//
//  LogManager.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 4/10/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import Foundation


public class LogManager {
    
    private static var logSQL = false
    
    internal static func shouldLog() -> Bool {
        return self.logSQL
    }
    
    internal static func log(string: String) {
        if logSQL {
            print(string)
        }
    }
    
    public static func startLogging() {
        self.logSQL = true
    }
    
    public static func stopLogging() {
        self.logSQL = false
    }
    
}