import Foundation

// Skyflow Validation Error object type
public typealias SkyflowValidationError = String

// Default validation error types
public enum SkyflowValidationErrorType: String {
  // Default Validation error for `SkyflowValidatePattern`
  case pattern = "PATTERN_VALIDATION_ERROR"
  
  // Default Validation error for `SkyflowValidateLength`
  case length = "LENGTH_VALIDATION_ERROR"
  
  // Default Validation error for `SkyflowValidateLengthMatch`
  case lengthMathes = "LENGTH_RANGE_MATCH_VALIDATION_ERROR"
  
}
