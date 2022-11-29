/*
 * Copyright (c) 2022 Skyflow
 */

import Foundation

public struct InsertOptions {
    var tokens: Bool
    var upsert: [[String: Any]]?
    public init(tokens: Bool = true, upsert: [[String: Any]]? = nil) {
        self.tokens = tokens
        self.upsert = upsert
    }
}
