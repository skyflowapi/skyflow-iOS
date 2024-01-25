/*
 * Copyright (c) 2022 Skyflow
*/

#if os(iOS)
import UIKit
#endif


internal class Type
{
    var formatPattern: String
    var regex: String
    var validation: ValidationSet
    var keyboardType: UIKeyboardType
    
    var acceptableCharacters: CharacterSet?
    var maxLength: Int?

    internal required init( formatPattern: String, regex: String,
                            validation: ValidationSet, keyboardType: UIKeyboardType, acceptableCharacters: CharacterSet?=nil, maxLength: Int?=nil) {
        self.formatPattern = formatPattern
        self.regex = regex
        self.validation = validation
        self.keyboardType = keyboardType
        
        self.acceptableCharacters = acceptableCharacters
        self.maxLength = maxLength
    }
}

/// Type of `SkyflowTextField`.
public enum ElementType: Int, CaseIterable {
    /// Field type that requires Cardholder Name input formatting and validation.
    case CARDHOLDER_NAME

    /// Field type that requires Credit Card Number input formatting and validation.
    case CARD_NUMBER

    /// Field type that requires Card Expiration Date input formatting and validation, format can be set through CollectElementOptions, defaul is MM/YY
    case EXPIRATION_DATE

    /// Field type that requires Card CVV input formatting and validation.
    case CVV
    
    /// A generic field type without any validations
    case INPUT_FIELD
    
    /// Field type that requires Card PIN input formatting and validatoin
    case PIN
    
    /// Field type that requires Card Expiration Month formatting and validation (format: MM)
    case EXPIRATION_MONTH
    
    /// Field type that requires Card Expiration Year formatting and validation, format can be set through CollectElementOptions for YY, defaul is YYYY
    case EXPIRATION_YEAR
    

    var instance: Type? {
        var rules = ValidationSet()
        switch self {
        case .CARDHOLDER_NAME :
            rules.add(rule: RegexMatchRule(regex: "^([a-zA-Z\\ \\,\\.\\-\\']{2,})$",
                                                   error: SkyflowValidationErrorType.regex.rawValue))
            return Type(formatPattern: "", regex: "^([a-zA-Z\\ \\,\\.\\-\\']{2,})$",
                        validation: rules, keyboardType: .alphabet, acceptableCharacters: CharacterSet.CardHolderCharacters)

        case .CARD_NUMBER :
            rules.add(rule: SkyflowValidateCardNumber(error: SkyflowValidationErrorType.cardNumber.rawValue, regex: "^$|^[\\s]*?([0-9]{2,6}[ |-]?){3,5}[\\s]*$"))
            return Type(formatPattern: "#### #### #### ####",
                        regex: "^$|^[\\s]*?([0-9]{2,6}[ -]?){3,5}[\\s]*$",
                        validation: rules, keyboardType: .numberPad, acceptableCharacters: CharacterSet.SkyflowAsciiDecimalDigits)

        case .EXPIRATION_DATE :
            let cardExpRegex = "(^(0[1-9]|1[0-2])\\/?([0-9]{4}|[0-9]{2})$|^([0-9]{4}|[0-9]{2})\\/?(0[1-9]|1[0-2])$)"
            rules.add(rule: RegexMatchRule(regex: cardExpRegex,
                                                   error: SkyflowValidationErrorType.regex.rawValue))
            return Type(formatPattern: "##/##", regex: cardExpRegex,
                        validation: rules, keyboardType: .numberPad, acceptableCharacters: CharacterSet.SkyflowAsciiDecimalDigits, maxLength: 7)

        case .CVV :
            rules.add(rule: RegexMatchRule(regex: "\\d*$",
                                                   error: SkyflowValidationErrorType.regex.rawValue))
            rules.add(rule: SkyflowValidateLengthMatch(lengths: [3, 4], error: SkyflowValidationErrorType.lengthMatches.rawValue))
            return Type(formatPattern: "", regex: "\\d*$",
                        validation: rules, keyboardType: .numberPad, acceptableCharacters: CharacterSet.SkyflowAsciiDecimalDigits, maxLength: 4)
        
        case .INPUT_FIELD:
            return nil
        
        case .PIN:
        rules.add(rule: RegexMatchRule(regex: "\\d*$",
                                               error: SkyflowValidationErrorType.regex.rawValue))
            rules.add(rule: SkyflowValidateLengthMatch(lengths: (4..<13).map({$0}), error: SkyflowValidationErrorType.lengthMatches.rawValue))
        return Type(formatPattern: "", regex: "\\d*$",
                    validation: rules, keyboardType: .numberPad, acceptableCharacters: CharacterSet.SkyflowAsciiDecimalDigits, maxLength: 12)
        case .EXPIRATION_MONTH:
            let monthRegex = "^(0[1-9]|1[0-2]|1)$"
            rules.add(rule: RegexMatchRule(regex: monthRegex,
                      error: SkyflowValidationErrorType.regex.rawValue))
            
            return Type(formatPattern: "", regex: monthRegex, validation: rules, keyboardType: .numberPad, acceptableCharacters: CharacterSet.SkyflowAsciiDecimalDigits, maxLength: 2)
        case .EXPIRATION_YEAR:
            let yearRegex = "^([0-9]{4}|[0-9]{2})$"
            rules.add(rule: RegexMatchRule(regex: yearRegex, error: SkyflowValidationErrorType.regex.rawValue))
            
            return Type(formatPattern: "", regex: yearRegex, validation: rules, keyboardType: .numberPad, acceptableCharacters: CharacterSet.SkyflowAsciiDecimalDigits, maxLength: 4)
        }
    }
    
    var name: String {
        switch self {
        case .CARDHOLDER_NAME: return "CARDHOLDER_NAME"
        case .CARD_NUMBER: return "CARD_NUMBER"
        case .EXPIRATION_DATE: return "EXPIRATION_DATE"
        case .CVV: return "CVV"
        case .INPUT_FIELD: return "INPUT_FIELD"
        case .PIN: return "PIN"
        case .EXPIRATION_MONTH: return "EXPIRATION_MONTH"
        case .EXPIRATION_YEAR: return "EXPIRATION_YEAR"
        }
    }
}
