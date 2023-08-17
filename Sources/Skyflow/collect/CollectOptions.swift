/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes the option of Collect

import Foundation

/// Options for a Collect Element.
public struct CollectOptions {
    var tokens: Bool
    var additionalFields: [String: Any]?
    var upsert: [[String: Any]]?

    /**
    Initializes the Collect options.

    - Parameters:
        - tokens: If `true`, returns tokens for the collected data. Defaults to `true`.
        - additionalFields: Additional, non-sensitive data to insert into the vault.
        - upsert: Upsert configuration for the element.
    */
    public init(tokens: Bool = true, additionalFields: [String: Any]? = nil, upsert: [[String:  Any]]? = nil) {
        self.tokens = tokens
        self.additionalFields = additionalFields
        self.upsert = upsert
    }
}
