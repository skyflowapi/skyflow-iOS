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

    /// Field type that requires Card Expiration Date input formatting and validation.
    case EXPIRATION_DATE

    /// Field type that requires Card CVV input formatting and validation.
    case CVV
    
    case INPUT_FIELD
    
    case PIN

    var instance: Type? {
        var rules = ValidationSet()
        switch self {
        case .CARDHOLDER_NAME :
            rules.add(rule: RegexMatchRule(regex: "^([a-zA-Z\\ \\,\\.\\-\\']{2,})$",
                                                   error: SkyflowValidationErrorType.regex.rawValue))
            return Type(formatPattern: "", regex: "^([a-zA-Z\\ \\,\\.\\-\\']{2,})$",
                        validation: rules, keyboardType: .alphabet, acceptableCharacters: CharacterSet.CardHolderCharacters)

        case .CARD_NUMBER :
            rules.add(rule: SkyflowValidateCardNumber(error: SkyflowValidationErrorType.cardNumber.rawValue, regex: "^$|^[\\s]*?([0-9]{2,6}[ -]?){3,5}[\\s]*$"))            
            return Type(formatPattern: "#### #### #### ####",
                        regex: "^$|^[\\s]*?([0-9]{2,6}[ -]?){3,5}[\\s]*$",
                        validation: rules, keyboardType: .numberPad, acceptableCharacters: CharacterSet.SkyflowAsciiDecimalDigits)

        case .EXPIRATION_DATE :
            rules.add(rule: RegexMatchRule(regex: "^(0[1-9]|1[0-2])\\/?([0-9]{4}|[0-9]{2})$",
                                                   error: SkyflowValidationErrorType.regex.rawValue))
            rules.add(rule: SkyflowValidateCardExpirationDate(error: SkyflowValidationErrorType.expirationDate.rawValue))
            return Type(formatPattern: "##/##", regex: "^(0[1-9]|1[0-2])\\/?([0-9]{4}|[0-9]{2})$",
                        validation: rules, keyboardType: .numberPad, acceptableCharacters: CharacterSet.SkyflowAsciiDecimalDigits, maxLength: 5)

        case .CVV :
            rules.add(rule: RegexMatchRule(regex: "\\d*$",
                                                   error: SkyflowValidationErrorType.regex.rawValue))
            rules.add(rule: SkyflowValidateLengthMatch(lengths: [3, 4], error: SkyflowValidationErrorType.lengthMatches.rawValue))
            return Type(formatPattern: "####", regex: "\\d*$",
                        validation: rules, keyboardType: .numberPad, acceptableCharacters: CharacterSet.SkyflowAsciiDecimalDigits, maxLength: 4)
        
        case .INPUT_FIELD:
            return nil
        
        case .PIN:
        rules.add(rule: RegexMatchRule(regex: "\\d*$",
                                               error: SkyflowValidationErrorType.regex.rawValue))
            rules.add(rule: SkyflowValidateLengthMatch(lengths: (4..<13).map({$0}), error: SkyflowValidationErrorType.lengthMatches.rawValue))
        return Type(formatPattern: "####", regex: "\\d*$",
                    validation: rules, keyboardType: .numberPad, acceptableCharacters: CharacterSet.SkyflowAsciiDecimalDigits, maxLength: 12)
        }
    }
}
