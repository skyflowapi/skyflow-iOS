
import Foundation

/**
Validate input in scope of length.
*/
public struct SkyflowValidateLength: SkyflowValidationProtocol {
    
    
    public let min: Int
  
    public let max: Int
  
    // Validation Error
    public let error: SkyflowValidationError

    public init(min: Int = 0, max: Int = Int.max, error: SkyflowValidationError) {
        self.min = min
        self.max = max
        self.error = error
    }
    
    //validate length of input
   public  func validate(input: String?) -> Bool {

        guard let input = input else {
            return false
        }
        return input.count >= min && input.count <= max
    }
}


