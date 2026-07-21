/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes the option of Collect

import Foundation

public struct CollectOptions {
    public var tokens: Bool
    public var additionalFields: [String: Any]?
    public var upsert: [[String: Any]]?
    public init(tokens: Bool = true, additionalFields: [String: Any]? = nil, upsert: [[String:  Any]]? = nil) {
        self.tokens = tokens
        self.additionalFields = additionalFields
        self.upsert = upsert
    }
}
