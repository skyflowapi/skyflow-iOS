/*
 * Copyright (c) 2022 Skyflow
*/

/**
 Validate input in scope of Card Expiration Month, e.x.: [01, 12].
 */

import Foundation

internal struct SkyflowValidateExpirationMonth: ValidationRule {
    /// Validation Error
    public let error: SkyflowValidationError

    /// Initialzation
    public init(error: SkyflowValidationError) {
        self.error = error
    }
}

extension SkyflowValidateExpirationMonth: SkyflowInternalValidationProtocol {
    /// Validation function for expire date.
    public func validate(_ text: String?) -> Bool {
        
        guard let text = text else {
            return false
        }
        
        if text.isEmpty {
            return true
        }
        
        if text.count > 2 || text.count < 1 {
            return false
        }
        
        guard let month = Int(text) else {
            return false
        }
        
        return (month <= 12 && month > 0)
        
    }
}
