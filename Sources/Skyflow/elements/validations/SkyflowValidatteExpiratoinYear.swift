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
    /// Validation function for expire date.
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
        
        if year < presentYear || year > (presentYear + 20) {
            return false
        }
        
        return true
        
    }
}

