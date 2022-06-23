/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation

/// Skyflow Validation Error object type
public typealias SkyflowValidationError = String

/// Default validation error types
internal enum SkyflowValidationErrorType: String {
    /// Default Validation error for `SkyflowValidateCardNumber`
    case cardNumber = "INVALID_CARD_NUMBER"

    /// Default Validation error for `SkyflowValidateLength`
    case length = "LENGTH_MATCH_FAILED"

    /// Default Validation error for `SkyflowValidatePattern`
    case regex = "REGEX_MATCH_FAILED"

    /// Default Validation error for `SkyflowValidateLengthMatch`
    case lengthMatches = "INVALID_LENGTH"

    /// Default Validation error for `SkyflowValidateCardExpirationDate`
    case expirationDate = "INVALID_EXPIRATION_DATE"
    
    case elementValueMatch = "ELEMENT_VALUE_MATCH_FAILED"
    
    /// Default Validation error for `SkyflowValidateExpirationMonth`
    case expirationMonth = "INVALID_EXPIRATION_MONTH"
    
    /// Default Validation error for `SkyflowValidateExpirationYear`
    case expirationYear = "INVALID_EXPIRATOIN_YEAR"
}
