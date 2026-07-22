/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes the option of Collect

import Foundation

public struct CollectOptions {
    var tokens: Bool
    var additionalFields: [String: Any]?
    var upsert: [UpsertOption]?
    public init(tokens: Bool = true, additionalFields: [String: Any]? = nil, upsert: [UpsertOption]? = nil) {
        self.tokens = tokens
        self.additionalFields = additionalFields
        self.upsert = upsert
    }
}
