/*
 * Copyright (c) 2022 Skyflow
*/

// A single tokenized value for a collected field. A column can map to more than
// one CollectRecordToken when multiple token groups apply to the same field
// (e.g. deterministic and vault tokens both configured for the same column).

import Foundation

public struct CollectRecordToken {
    public let token: String
    public let tokenGroupName: String?
    public let path: String?

    public init(token: String, tokenGroupName: String? = nil, path: String? = nil) {
        self.token = token
        self.tokenGroupName = tokenGroupName
        self.path = path
    }

    // Parses one wire entry from a column's token array, e.g.
    // {"token": "...", "tokenGroupName": "...", "path": "..."}. Drops the entry (returns nil)
    // rather than crashing if "token" is missing or isn't a String.
    init?(dict: [String: Any]) {
        guard let token = dict["token"] as? String else { return nil }
        self.token = token
        self.tokenGroupName = dict["tokenGroupName"] as? String
        self.path = dict["path"] as? String
    }
}
