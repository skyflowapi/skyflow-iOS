/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes an upsert configuration for insert/collect calls

import Foundation

public enum UpdateType: String {
    case UPDATE
    case REPLACE
}

public struct UpsertOption {
    public let table: String
    public let uniqueColumns: [String]
    public let updateType: UpdateType?

    public init(table: String, uniqueColumns: [String], updateType: UpdateType? = nil) {
        self.table = table
        self.uniqueColumns = uniqueColumns
        self.updateType = updateType
    }
}
