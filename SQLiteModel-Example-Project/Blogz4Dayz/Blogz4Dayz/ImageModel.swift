//
//  ImageModel.swift
//  Blogz4Dayz
//
//  Created by Jeff Hurray on 4/9/16.
//  Copyright © 2016 jhurray. All rights reserved.
//

import Foundation
import SQLiteModel
import SQLite

protocol Image {
    var image: UIImage? {get}
    var title: String? {get}
}

struct ImageModel: SQLiteModel, Image {
    
    var localID: Int64 = -1
    
    static let Title = Expression<String?>("title")
    static let Data = Expression<NSData>("data")
    
    
    static func buildTable(tableBuilder: TableBuilder) {
        tableBuilder.column(Title)
        tableBuilder.column(Data)
    }
    
    // MARK: Image
    
    var image: UIImage? {
        let data = self => ImageModel.Data
        return UIImage(data: data)
    }
    
    var title: String? {
        return self => ImageModel.Title
    }
    
}