import Foundation

/**
Validate input in scope of matching the regex.
*/
public struct RegexMatch: ValidationRule {
    ///  regex to validate input
    public let regex: String

    /// Validation Error
    public let error: SkyflowValidationError

    public init(regex: String, error: SkyflowValidationError="Regex match failed") {
        self.regex = regex
        self.error = error
    }

}
extension RegexMatch: SkyflowInternalValidationProtocol {
    /// validate the text with specified regex
    public func validate(_ text: String?) -> Bool {
        if text!.isEmpty {
        return true
        }
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: text)
    }
}
