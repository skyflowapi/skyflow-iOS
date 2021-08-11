import Foundation

/// Skyflow Validation Error object type
internal typealias SkyflowValidationError = String

/// Default validation error types
internal enum SkyflowValidationErrorType: String {
    
    /// Default Validation error for `SkyflowValidateCardNumber`
    case cardNumber = "INVALID_CARD_NUMBER"
    
    /// Default Validation error for `SkyflowValidateLength`
    case length = "INVALID_LENGTH"
     
    /// Default Validation error for `SkyflowValidatePattern`
    case pattern = "INVALID_PATTERN"
  
    /// Default Validation error for `SkyflowValidateLengthMatch`
    case lengthMathes = "INVALID_LENGTH_MATCH"
    
    /// Default Validation error for `SkyflowValidateExpireDate`
    case expireDate = "INVALID_EXPIRE_DATE"
    
    
    
  
}
