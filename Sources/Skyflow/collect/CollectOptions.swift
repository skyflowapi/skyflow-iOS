/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes the option of Collect

import Foundation

/// This is the description for CollectOptions Class
public struct CollectOptions {
    var tokens: Bool
    var additionalFields: [String: Any]?
    var upsert: [[String: Any]]?

    /**
    This is the description for container method.

    - Parameters:
        - tokens: This is the description for tokens parameter.
        - additionalFields: This is the description for additionalFields parameter.
        - upsert: This is the description for upsert paramter.
    */
    public init(tokens: Bool = true, additionalFields: [String: Any]? = nil, upsert: [[String:  Any]]? = nil) {
        self.tokens = tokens
        self.additionalFields = additionalFields
        self.upsert = upsert
    }
}
