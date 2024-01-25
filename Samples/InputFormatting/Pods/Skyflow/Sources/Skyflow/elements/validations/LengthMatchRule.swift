/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation

// Validate input in scope of length.

public struct LengthMatchRule: ValidationRule {
    /// input string minimum length
    public let minLength: Int

    /// input string maximum length
    public let maxLength: Int

    /// Validation Error
    public let error: SkyflowValidationError

    public init(minLength: Int = 0, maxLength: Int = Int.max, error: SkyflowValidationError? = nil) {
        self.minLength = minLength
        self.maxLength = maxLength
        if error != nil {
            self.error = error!
        } else {
            self.error = SkyflowValidationErrorType.length.rawValue
        }
    }
}

extension LengthMatchRule: SkyflowInternalValidationProtocol {
    /// validate length of text
    public func validate(_ text: String?) -> Bool {
        
        guard text != nil else {
            return false
        }
        if text!.isEmpty {
            return true
        }
        return text!.count >= minLength && text!.count <= maxLength
    }
}
