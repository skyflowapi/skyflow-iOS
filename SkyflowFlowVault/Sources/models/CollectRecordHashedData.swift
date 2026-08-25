/*
 * Copyright (c) 2022 Skyflow
*/

// A single hashed value for a collected field. A column can map to more than one
// CollectRecordHashedData when multiple hash configurations apply to the same column.

import Foundation

public struct CollectRecordHashedData {
    public let data: String
    public let hashName: String

    public init(data: String, hashName: String) {
        self.data = data
        self.hashName = hashName
    }

    // Parses one wire entry from a column's hashedData array, e.g. {"data": "...", "hashName": "..."}.
    // Drops the entry (returns nil) rather than crashing if either key is missing or isn't a String.
    init?(dict: [String: Any]) {
        guard let data = dict["data"] as? String, let hashName = dict["hashName"] as? String else { return nil }
        self.data = data
        self.hashName = hashName
    }
}
