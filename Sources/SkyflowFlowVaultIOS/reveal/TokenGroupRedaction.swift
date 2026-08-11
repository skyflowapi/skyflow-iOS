/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes a request-level, per-token-group redaction for detokenize

import Foundation

public struct TokenGroupRedaction {
    public let tokenGroupName: String
    public let redaction: String

    public init(tokenGroupName: String, redaction: String) {
        self.tokenGroupName = tokenGroupName
        self.redaction = redaction
    }
}
