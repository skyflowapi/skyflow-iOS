/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation

public struct CollectResponse {
    public let records: [CollectRecord]

    public init?(_ responseBody: Any) {
        guard let dict = responseBody as? [String: Any],
              let recordDicts = dict["records"] as? [[String: Any]] else { return nil }
        self.records = recordDicts.map { CollectRecord($0) }
    }
}

// Each entry in "records" is either a successfully inserted/updated record (error is nil) or a
// failed one (error is non-nil) - the vault returns both together in the same array, each tagged
// with its own httpCode.
public struct CollectRecord {
    public let tableName: String?
    public let skyflowId: String?
    // Keyed by column name, e.g. "card_number": [Token(token: "...", tokenGroupName: "...")].
    // A column maps to more than one Token when multiple token groups apply to it.
    public let tokens: [String: [Token]]?
    // Keyed by column name, e.g. "card_number": [{"data": "...", "hashName": "..."}].
    public let hashedData: [String: Any]?
    public let httpCode: Int
    public let error: String?

    init(_ dict: [String: Any]) {
        self.tableName = dict["tableName"] as? String
        // Wire key is intentionally left as "skyflowID" here - only the public Swift-facing
        // property name changed, not the response dict this reads from.
        self.skyflowId = dict["skyflowID"] as? String
        // Dict key is intentionally left as "fields" here - only the public Swift-facing
        // property name changed, not the response dict this reads from. Malformed entries
        // (wrong shape, missing "token") are dropped rather than crashing.
        self.tokens = (dict["fields"] as? [String: Any])?.compactMapValues { value in
            (value as? [[String: Any]])?.compactMap(Token.init(dict:))
        }
        self.hashedData = dict["hashedData"] as? [String: Any]
        self.httpCode = dict["httpCode"] as? Int ?? 0
        self.error = dict["error"] as? String
    }
}
