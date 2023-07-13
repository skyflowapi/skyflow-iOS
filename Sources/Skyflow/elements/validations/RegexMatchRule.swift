/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation

/**
Validate input in scope of matching the regex.
*/
public struct RegexMatchRule: ValidationRule {
    ///  regex to validate input
    public let regex: String

    /// Validation Error
    public let error: SkyflowValidationError

    /// This is the description for init method.
    public init(regex: String, error: SkyflowValidationError?=nil) {
        self.regex = regex
        if error != nil {
            self.error = error!
        } else {
            self.error = SkyflowValidationErrorType.regex.rawValue
        }
    }

}
extension RegexMatchRule: SkyflowInternalValidationProtocol {
    /**
    validate the text with specified regex

    - Parameters:
        - _ text: This is the description for _ text parameter.

    - Returns: This is the description of what method returns.
    */
    public func validate(_ text: String?) -> Bool {
        if text!.isEmpty {
        return true
        }
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: text)
    }
}
