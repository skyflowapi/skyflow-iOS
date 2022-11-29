/*
 * Copyright (c) 2022 Skyflow
 */

import Foundation

public struct CollectOptions {
    var tokens: Bool
    var additionalFields: [String: Any]?
    var upsert: [[String: Any]]?
    public init(
        tokens: Bool = true,
        additionalFields: [String: Any]? = nil,
        upsert: [[String: Any]]? = nil
    ) {
        self.tokens = tokens
        self.additionalFields = additionalFields
        self.upsert = upsert
    }
}
