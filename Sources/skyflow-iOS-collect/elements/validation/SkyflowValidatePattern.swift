

import Foundation

/**
Validate input in scope of matching the regex.
*/
public struct SkyflowValidatePattern: SkyflowValidationProtocol {
  
    // Regex pattern
    public let pattern: String
  
    // Validation Error
    public let error: SkyflowValidationError
   
    public init(pattern: String, error: SkyflowValidationError) {
        self.pattern = pattern
        self.error = error
    }
    
     public func validate(input: String?) -> Bool {

        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: input)
    }
}


