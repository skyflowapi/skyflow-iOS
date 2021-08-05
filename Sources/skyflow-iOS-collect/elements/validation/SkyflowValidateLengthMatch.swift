import Foundation

/**
Validate input in scope of multiple lengths, e.x.: [20, 29].
*/
public struct SkyflowValidateLengthMatch: SkyflowValidationProtocol {
    
    // Array of valid length ranges
    public let lengths: [Int]
  
    // Validation Error
    public let error: SkyflowValidationError

     public init(lengths: [Int], error: SkyflowValidationError) {
        self.lengths = lengths
        self.error = error
    }
    
    // validate the input
     public func validate(input: String?) -> Bool {

      guard let input = input else {
          return false
      }
      return lengths.contains(input.count)
    }
}

