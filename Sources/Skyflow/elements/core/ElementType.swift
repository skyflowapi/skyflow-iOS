#if os(iOS)
import UIKit
#endif


internal class Type
{
    var formatPattern: String
    var regex: String
    var validation: SkyflowValidationSet
    var keyboardType: UIKeyboardType

    internal required init( formatPattern: String, regex: String,
                          validation: SkyflowValidationSet, keyboardType: UIKeyboardType) {
        self.formatPattern = formatPattern
        self.regex = regex
        self.validation = validation
        self.keyboardType = keyboardType
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

    var instance: Type? {
        var rules = SkyflowValidationSet()
        switch self {
        case .CARDHOLDER_NAME :
            rules.add(rule: SkyflowValidatePattern(regex: "^([a-zA-Z\\ \\,\\.\\-\\']{2,})$",
                                                   error: SkyflowValidationErrorType.pattern.rawValue))
            return Type(formatPattern: "", regex: "^([a-zA-Z\\ \\,\\.\\-\\']{2,})$",
                        validation: rules, keyboardType: .alphabet)

        case .CARD_NUMBER :
            rules.add(rule: SkyflowValidateCardNumber(error: SkyflowValidationErrorType.cardNumber.rawValue, regex: "^$|^[\\s]*?([0-9]{2,6}[ -]?){3,5}[\\s]*$"))
            return Type(formatPattern: "#### #### #### ####",
                        regex: "^$|^[\\s]*?([0-9]{2,6}[ -]?){3,5}[\\s]*$",
                        validation: rules, keyboardType: .numberPad)

        case .EXPIRATION_DATE :
            rules.add(rule: SkyflowValidatePattern(regex: "^(0[1-9]|1[0-2])\\/?([0-9]{4}|[0-9]{2})$",
                                                   error: SkyflowValidationErrorType.pattern.rawValue))
            rules.add(rule: SkyflowValidateCardExpirationDate(error: SkyflowValidationErrorType.expirationDate.rawValue))
            return Type(formatPattern: "##/##", regex: "^(0[1-9]|1[0-2])\\/?([0-9]{4}|[0-9]{2})$",
                        validation: rules, keyboardType: .numberPad)

        case .CVV :
            rules.add(rule: SkyflowValidatePattern(regex: "\\d*$",
                                                   error: SkyflowValidationErrorType.pattern.rawValue))
            rules.add(rule: SkyflowValidateLengthMatch(lengths: [3, 4], error: SkyflowValidationErrorType.lengthMatches.rawValue))
            return Type(formatPattern: "####", regex: "\\d*$",
                        validation: rules, keyboardType: .numberPad)
        
        case .INPUT_FIELD:
            return nil
        }
    }
}
