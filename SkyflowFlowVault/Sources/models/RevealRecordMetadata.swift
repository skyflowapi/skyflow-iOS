/*
 * Copyright (c) 2022 Skyflow
*/

// Typed shape for RevealRecord.metadata, e.g. {"tableName": "customer", "skyflowId": "..."} -
// the exact shape reported from a real device run.

import Foundation

public struct RevealRecordMetadata {
    public let tableName: String?
    public let skyflowId: String?

    public init(tableName: String? = nil, skyflowId: String? = nil) {
        self.tableName = tableName
        self.skyflowId = skyflowId
    }
    init?(dict: [String: Any]?) {
        guard let dict = dict else { return nil }
        self.tableName = dict["tableName"] as? String
        self.skyflowId = (dict["skyflowID"] as? String) ?? (dict["skyflowId"] as? String)
    }
}
