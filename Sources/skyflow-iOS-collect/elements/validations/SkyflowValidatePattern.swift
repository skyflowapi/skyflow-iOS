import Foundation

/**
Validate input in scope of matching the regex.
*/
internal struct SkyflowValidatePattern: SkyflowValidationProtocol {
  
    ///  regex to validate input
    public let regex: String
  
    /// Validation Error
    public let error: SkyflowValidationError
   
    public init(regex: String, error: SkyflowValidationError) {
        self.regex = regex
        self.error = error
    }
    
    /// validate the text with specified regex
     public func validate(text: String?) -> Bool {
        if(text!.isEmpty)
        {
        return true
        }
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: text)
    }
}


