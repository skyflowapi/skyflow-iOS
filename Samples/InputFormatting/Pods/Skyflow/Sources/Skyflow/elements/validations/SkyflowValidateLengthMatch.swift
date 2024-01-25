/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation

/**
 Validate input in scope of multiple lengths, e.x.: [10, 15].
 */

internal struct SkyflowValidateLengthMatch: ValidationRule {
    /// Array of valid length ranges
    public let lengths: [Int]

    /// Validation Error
    public let error: SkyflowValidationError

     public init(lengths: [Int], error: SkyflowValidationError) {
        self.lengths = lengths
        self.error = error
    }
}

extension SkyflowValidateLengthMatch: SkyflowInternalValidationProtocol {
    /// validate the text
    public func validate(_ text: String?) -> Bool {
        guard let text = text else {
            return false
        }
        if text.isEmpty {
            return true
        }
        return lengths.contains(text.count)
    }
}
