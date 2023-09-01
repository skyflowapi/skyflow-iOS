/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes the Options for Insert

import Foundation

/// Contains additional parameters for the insert method.
public struct InsertOptions {
    var tokens: Bool
    var upsert: [[String: Any]]?

    /**
    Initializes the Insert options.

    - Parameters:
        - tokens: If `true`, returns tokens for the collected data. Defaults to `false`.
        - upsert: If specified, upserts data. If not specified, inserts data.
    */
    public init(tokens: Bool = true, upsert: [[String:  Any]]? = nil) {
        self.tokens = tokens
        self.upsert = upsert
    }
}
