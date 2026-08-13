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
    public let tableName: String
    public let uniqueColumns: [String]
    public let updateType: UpdateType?

    public init(tableName: String, uniqueColumns: [String], updateType: UpdateType? = nil) {
        self.tableName = tableName
        self.uniqueColumns = uniqueColumns
        self.updateType = updateType
    }
}
