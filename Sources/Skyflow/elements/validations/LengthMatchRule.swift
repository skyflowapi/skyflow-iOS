/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation

/// Validate input in scope of length.
public struct LengthMatchRule: ValidationRule {
    /// Minimum length of input string.
    public let minLength: Int

    /// Maximum length of input string.
    public let maxLength: Int

    /// Validation Error
    public let error: SkyflowValidationError

    ///  Initializes the rule to set the minimum and maximum permissible length of the textfield value.
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
    /**
    Validates the length of the input text within the specified range.

    - Parameters:
        - text: Text that needs to be validated.

    - Returns: Returns `true` if the text length is within the specified range, else `false`.
    */
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
