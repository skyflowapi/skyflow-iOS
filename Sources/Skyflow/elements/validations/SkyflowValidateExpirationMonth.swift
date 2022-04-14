internal struct SkyflowValidateExpirationMonth: ValidationRule {
    /// Validation Error
    public let error: SkyflowValidationError
    public let format: String

    /// Initialzation
    public init(format: String, error: SkyflowValidationError) {
        self.error = error
        self.format = format
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
        
        if text.count != format.count {
            return false
        }
        
        guard let month = Int(text) else {
            return false
        }
        
        return (month <= 12 && month > 0)
        
    }
}
