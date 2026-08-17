/*
 * Copyright (c) 2022 Skyflow
*/

//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 21/09/21.
//

import Foundation

package struct GetByIdRecord {
    var ids: [String]
    var table: String
    var redaction: String
    package init(ids: [String], table: String, redaction: String) {
        self.ids = ids
        self.table = table
        self.redaction = redaction
    }
}
