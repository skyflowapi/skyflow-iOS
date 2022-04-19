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
        
        if text.count != 2 {
            return false
        }
        
        guard let month = Int(text) else {
            return false
        }
        
        return (month <= 12 && month > 0)
        
    }
}
