
#if os(iOS)
import UIKit
#endif


internal class Type
{
    var formatPattern:String
    var regex: String
    var validation: SkyflowValidationSet
    var keyboardType: UIKeyboardType
    
    internal required init( formatPattern:String,regex: String,
                          validation: SkyflowValidationSet,keyboardType: UIKeyboardType) {
        self.formatPattern = formatPattern
        self.regex = regex
        self.validation = validation
        self.keyboardType = keyboardType
    }
}

/// Type of `SkyflowTextField`.
public enum SkyflowElementType: Int, CaseIterable {
    
    
    /// Field type that requires Cardholder Name input formatting and validation.
    case cardHolderName
    
    /// Field type that requires Credit Card Number input formatting and validation.
    case cardNumber
    
    /// Field type that requires Expire Date input formatting and validation.
    case expireDate
    
    /// Field type that requires Card CVV input formatting and validation.
    case cvv
    
    /// Field type that doesn't require any input formatting and validation.
    case none
    
    
    var instance: Type {
        var rules = SkyflowValidationSet()
        switch self {
        case .cardHolderName :
            rules.add(rule: SkyflowValidatePattern(regex: "^([a-zA-Z0-9\\ \\,\\.\\-\\']{2,})$",
                                                   error: SkyflowValidationErrorType.pattern.rawValue))
            return Type(formatPattern: "", regex: "^([a-zA-Z0-9\\ \\,\\.\\-\\']{2,})$",
                        validation: rules, keyboardType: .alphabet)
            
        case .cardNumber :
            rules.add(rule: SkyflowValidateCardNumber(error: SkyflowValidationErrorType.cardNumber.rawValue))
            return Type(formatPattern: "#### #### #### ####",
                        regex:"^(?:4[0-9]{12}(?:[0-9]{3})?|[25][1-7][0-9]{14}|6(?:011|5[0-9][0-9])[0-9]{12}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{11}|(?:2131|1800|35\\d{3})\\d{11})$",
                        validation: rules, keyboardType: .numberPad)
            
        case .expireDate :
            rules.add(rule: SkyflowValidatePattern(regex: "^(0[1-9]|1[0-2])\\/?([0-9]{4}|[0-9]{2})$",
                                                   error: SkyflowValidationErrorType.pattern.rawValue))
            rules.add(rule: SkyflowValidateExpireDate(dateFormat:SkyflowExpireDateFormat.shortYear,error: SkyflowValidationErrorType.expireDate.rawValue))
            return Type(formatPattern: "##/##", regex: "^(0[1-9]|1[0-2])\\/?([0-9]{4}|[0-9]{2})$",
                        validation: rules, keyboardType: .numberPad)
            
        case .cvv :
            rules.add(rule: SkyflowValidatePattern(regex: "\\d*$",
                                                   error: SkyflowValidationErrorType.pattern.rawValue))
            rules.add(rule: SkyflowValidateLengthMatch(lengths: [3, 4], error: SkyflowValidationErrorType.lengthMathes.rawValue))
            return Type(formatPattern: "####", regex: "\\d*$",
                        validation: rules, keyboardType: .numberPad)
            
        case .none :
            return Type(formatPattern: "", regex: "",
                        validation: rules, keyboardType: .numberPad)
        }
    }
  
}
