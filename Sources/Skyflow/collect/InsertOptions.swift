/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes the Options for Insert

import Foundation

public struct InsertOptions {
    var tokens: Bool
    var upsert: [UpsertOption]?
    public init(tokens: Bool = true, upsert: [UpsertOption]? = nil) {
        self.tokens = tokens
        self.upsert = upsert
    }
}
