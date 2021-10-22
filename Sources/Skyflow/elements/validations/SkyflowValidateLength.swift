import Foundation

/**
Validate input in scope of length.
*/
internal struct SkyflowValidateLength: SkyflowValidationProtocol {
    /// input string minimum length
    public let minLength: Int

    /// input string maximum length
    public let maxLength: Int

    /// Validation Error
    public let error: SkyflowValidationError

    public init(minLength: Int = 0, maxLength: Int = Int.max, error: SkyflowValidationError) {
        self.minLength = minLength
        self.maxLength = maxLength
        self.error = error
    }

    /// validate length of text
   public  func validate(text: String?) -> Bool {
        
        print("====>", text)
        guard text != nil else {
            print("-------->here")
            return false
        }
        if text!.isEmpty {
            return true
        }
        return text!.count >= minLength && text!.count <= maxLength
    }
}
