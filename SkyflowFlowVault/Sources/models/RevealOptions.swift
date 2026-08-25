/*
 * Copyright (c) 2022 Skyflow
*/

// Options for the reveal() operation: per-token-group redaction (FlowVault contract).

import Foundation

public struct RevealOptions {
    public let tokenGroupRedactions: [TokenGroupRedaction]?

    public init(tokenGroupRedactions: [TokenGroupRedaction]? = nil) {
        self.tokenGroupRedactions = tokenGroupRedactions
    }
}
