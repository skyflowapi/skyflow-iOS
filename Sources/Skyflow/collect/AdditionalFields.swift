/*
 * Copyright (c) 2022 Skyflow
*/

// Typed replacement for the old [String: Any] additionalFields shape on CollectOptions -
// non-PCI records to insert/update alongside whatever's collected from mounted elements.

import Foundation

public struct AdditionalFieldsRecord {
    public let tableName: String
    public let data: [String: Any]
    // Present to update an existing record, absent to insert a new one.
    public let skyflowId: String?

    public init(tableName: String, data: [String: Any], skyflowId: String? = nil) {
        self.tableName = tableName
        self.data = data
        self.skyflowId = skyflowId
    }
}

public struct AdditionalFields {
    public let records: [AdditionalFieldsRecord]

    public init(records: [AdditionalFieldsRecord]) {
        self.records = records
    }
}
