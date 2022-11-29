/*
 * Copyright (c) 2022 Skyflow
 */

import Foundation

struct GetByIdRecord {
    var ids: [String]
    var table: String
    var redaction: String
    init(ids: [String], table: String, redaction: String) {
        self.ids = ids
        self.table = table
        self.redaction = redaction
    }
}
