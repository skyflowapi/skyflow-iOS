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
    This is the description for init method.

    - Parameters:
        - element: This is the description for element parameter.
        - error: Validation Error.
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
    validate element value

    - Parameters:
        - text: This is the description for text parameter.

    - Returns: This is the description of what method returns.
    */
    public func validate(_ text: String?) -> Bool {
        guard text != nil else {
            return false
        }
        return text! == (element as! TextField).actualValue
    }
}
