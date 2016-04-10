//
//  BlogModel.swift
//  Blogz4Dayz
//
//  Created by Jeff Hurray on 4/9/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import Foundation
import SQLiteModel
import SQLite

struct BlogModel: SQLiteModel {
    
    var localID: Int64 = -1
    
    static let Title = Expression<String>("title")
    static let Body = Expression<String>("body")
    static let Images = Relationship<[ImageModel]>("images")
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(Title, defaultValue: "")
        tableBuilder.column(Body, defaultValue: "")
        tableBuilder.relationship(Images, mappedFrom: self)
    }
}