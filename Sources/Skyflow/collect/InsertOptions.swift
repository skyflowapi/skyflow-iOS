/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes the Options for Insert

import Foundation

/// This is the description for InsertOptions Class
public struct InsertOptions {
    var tokens: Bool
    var upsert: [[String: Any]]?

    /**
    This is the description for container method.

    - Parameters:
        - tokens: This is the description for tokens parameter.
        - upsert: This is the description for upsert parameter.
    */
    public init(tokens: Bool = true, upsert: [[String:  Any]]? = nil) {
        self.tokens = tokens
        self.upsert = upsert
    }
}
