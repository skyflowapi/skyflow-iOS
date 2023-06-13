//
//  File.swift
//  
//
//  Created by Bharti Sagar on 13/06/23.
//

import Foundation

struct GetRecord {
    var ids: [String]?
    var table: String
    var redaction: String?
    var columnName: String?
    var columnValues: [String]?
    
    init(ids: [String], table: String, redaction: String) {
        self.ids = ids
        self.table = table
        self.redaction = redaction
    }
    init(ids: [String], table: String) {
        self.ids = ids
        self.table = table
    }
    init(columnValues: [String], table: String, columnName: String, redaction: String) {
        self.columnValues = columnValues
        self.table = table
        self.columnName = columnName
        self.redaction = redaction
    }
}
