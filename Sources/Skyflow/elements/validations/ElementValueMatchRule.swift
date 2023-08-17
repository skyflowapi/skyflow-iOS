/*
 * Copyright (c) 2022 Skyflow
*/


import Foundation

/**
 Validate input if it matches with that of another element
 */
public struct ElementValueMatchRule: ValidationRule {
    /// element to be matched against
    private let element: TextField
    
    /// Validation Error
    public let error: SkyflowValidationError
    
    /**
    Initializes the rule to match the value of one element with another.

    - Parameters:
        - element: Element whose value needs to be matched.
        - error: Custom validation error.
    */
    public init(element: TextField, error: SkyflowValidationError? = nil) {
        self.element = element
        if error != nil {
            self.error = error!
        } else {
            self.error = SkyflowValidationErrorType.elementValueMatch.rawValue
        }
    }
}

extension ElementValueMatchRule: SkyflowInternalValidationProtocol {
    /**
    Validates the element's value against the specified text.

    - Parameters:
        - text: Text that needs to be validated.

    - Returns: Returns `true` if the text matches the value of the element, else `false`.
    */
    public func validate(_ text: String?) -> Bool {
        guard text != nil else {
            return false
        }
        return text! == (element as! TextField).actualValue
    }
}
