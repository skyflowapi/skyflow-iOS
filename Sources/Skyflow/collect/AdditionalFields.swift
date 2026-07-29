/*
 * Copyright (c) 2022 Skyflow
*/

// Typed replacement for the old [String: Any] additionalFields shape on CollectOptions -
// non-PCI records to insert/update alongside whatever's collected from mounted elements.

import Foundation

public struct AdditionalFieldsRecord {
    public let table: String
    public let fields: [String: Any]
    // Present to update an existing record, absent to insert a new one.
    public let skyflowId: String?

    public init(table: String, fields: [String: Any], skyflowId: String? = nil) {
        self.table = table
        self.fields = fields
        self.skyflowId = skyflowId
    }
}

public struct AdditionalFields {
    public let records: [AdditionalFieldsRecord]

    public init(records: [AdditionalFieldsRecord]) {
        self.records = records
    }
}
