//
//  SQLiteModelError.swift
//  SQLiteModel
//
//  Created by Jeff Hurray on 12/24/15.
//  Copyright © 2015 jhurray. All rights reserved.
//

import Foundation

public enum SQLiteModelError : ErrorType {
    
    case CreateError
    case DropError
    case InsertError
    case UpdateError
    case DeleteError
    case FetchError
    case IndexError
    
    func errorMessage(type modelType: Any.Type, model: Any?) -> String {
        
        var message: String
        
        switch self {
        case .CreateError:
             message = "SQLiteModel Create Table Error: "
        case .DropError:
            message =  "SQLiteModel Drop Table Error: "
        case .InsertError:
            message =  "SQLiteModel Insert Error: "
        case .UpdateError:
            message =  "SQLiteModel Update Error: "
        case .DeleteError:
            message =  "SQLiteModel Delete Error: "
        case .FetchError:
            message =  "SQLiteModel Fetch Error: "
        case .IndexError:
            message =  "SQLiteModel CreateIndex Error: "
        }
        message += "Type: \(modelType)"
        if let instance = model {
            message += " Instance: \(instance)"
        }
        return message
    }
    
    func logError(modelType: Any.Type, error: ErrorType, model: Any? = nil) -> Void {
        LogManager.log("SQLiteModel: Caught error: \(error)")
        LogManager.log(self.errorMessage(type: modelType, model: model))
        LogManager.log("SQLiteModel: Throwing error: \(self)")
    }
    
}