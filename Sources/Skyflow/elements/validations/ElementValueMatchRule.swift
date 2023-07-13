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
    
    /// This is description for init method
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
    validate element value

    - Parameters:
        - _ text: This is the description for _ text parameter.

    - Returns: This is the description of what method returns.
    */
    public func validate(_ text: String?) -> Bool {
        guard text != nil else {
            return false
        }
        return text! == (element as! TextField).actualValue
    }
}
