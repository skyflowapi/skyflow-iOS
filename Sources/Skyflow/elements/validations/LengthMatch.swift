import Foundation

/**
Validate input in scope of length.
*/
public struct LengthMatch: ValidationRule {
    /// input string minimum length
    public let minLength: Int

    /// input string maximum length
    public let maxLength: Int

    /// Validation Error
    public let error: SkyflowValidationError

    public init(minLength: Int = 0, maxLength: Int = Int.max, error: SkyflowValidationError="Length match failed") {
        self.minLength = minLength
        self.maxLength = maxLength
        self.error = error
    }
}

extension LengthMatch: SkyflowInternalValidationProtocol {
    /// validate length of text
    public  func validate(_ text: String?) -> Bool {
        
        guard text != nil else {
            return false
        }
        if text!.isEmpty {
            return true
        }
        return text!.count >= minLength && text!.count <= maxLength
    }
}