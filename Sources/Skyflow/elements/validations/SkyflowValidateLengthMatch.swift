import Foundation

/**
Validate input in scope of multiple lengths, e.x.: [10, 15].
*/
internal struct SkyflowValidateLengthMatch: SkyflowValidationProtocol {
    /// Array of valid length ranges
    public let lengths: [Int]

    /// Validation Error
    public let error: SkyflowValidationError

     public init(lengths: [Int], error: SkyflowValidationError) {
        self.lengths = lengths
        self.error = error
    }

    /// validate the text
     public func validate(text: String?) -> Bool {
        if text!.isEmpty {
        return true
        }
      guard let text = text else {
          return false
      }
      return lengths.contains(text.count)
    }
}
