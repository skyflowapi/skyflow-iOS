/*
 * Copyright (c) 2022 Skyflow
*/

// A single tokenized value for a collected field. A column can map to more than
// one Token when multiple token groups apply to the same field (e.g. deterministic
// and vault tokens both configured for the same column).

import Foundation

public struct Token {
    public let token: String
    public let tokenGroupName: String?

    public init(token: String, tokenGroupName: String? = nil) {
        self.token = token
        self.tokenGroupName = tokenGroupName
    }

    // Parses one wire entry from a column's token array, e.g. {"token": "...", "tokenGroupName": "..."}.
    // Drops the entry (returns nil) rather than crashing if "token" is missing or isn't a String.
    init?(dict: [String: Any]) {
        guard let token = dict["token"] as? String else { return nil }
        self.token = token
        self.tokenGroupName = dict["tokenGroupName"] as? String
    }
}
