/*
 * Copyright (c) 2022 Skyflow
*/

/**
 Validate input in scope of Card Expiration Year, e.x.: [2018, 2029].
 */

import Foundation

internal struct SkyflowValidateExpirationYear: ValidationRule {
    /// Validation Error
    public let error: SkyflowValidationError
    public let format: String

    /// Initialzation
    public init(format: String, error: SkyflowValidationError) {
        self.error = error
        self.format = format
    }
}

extension SkyflowValidateExpirationYear: SkyflowInternalValidationProtocol {
    /// Validation function for expiry year.
    public func validate(_ text: String?) -> Bool {
        
        guard let text = text else {
            return false
        }
        
        if text.isEmpty {
            return true
        }
        
        if text.count != format.count {
            return false
        }
        
        guard var year = Int(text) else {
            return false
        }
        
        let presentYear = Calendar(identifier: .gregorian).component(.year, from: Date())
        year = format.count == 2 ? (year + 2000) : year
        

        
        return (year >= presentYear && year <= presentYear + 50)
        
    }
}

