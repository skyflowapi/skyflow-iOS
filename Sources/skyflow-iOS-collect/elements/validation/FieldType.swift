//


#if os(iOS)
import UIKit
#endif



/// Type of `SkyflowTextField` configuration.
public enum FieldType: Int, CaseIterable {
    
    /// Field type that doesn't require any input formatting and validation.
    case none
    
    /// Field type that requires Credit Card Number input formatting and validation.
    case cardNumber
    
    /// Field type that requires Expiration Date input formatting and validation.
    case expDate
    
    /// Field type that requires Credit Card CVC input formatting and validation.
    case cvc
    
    /// Field type that requires Cardholder Name input formatting and validation.
    case cardHolderName
  
}



internal extension FieldType {
    
    var defaultFormatPattern: String {
        switch self {
        case .cardNumber:
            return "#### #### #### ####"
        case .cvc:
            return "####"
        case .expDate:
            return DateFormatPattern.shortYear.rawValue
        default:
            return ""
        }
    }
    
    
    
   var defaultRegex: String {
        switch self {
        case .cardNumber:
            return "^(?:4[0-9]{12}(?:[0-9]{3})?|[25][1-7][0-9]{14}|6(?:011|5[0-9][0-9])[0-9]{12}|3[47][0-9]{13}|3(?:0[0-5]|[68][0-9])[0-9]{11}|(?:2131|1800|35\\d{3})\\d{11})$"
        case .expDate:
            return "^(0[1-9]|1[0-2])\\/?([0-9]{4}|[0-9]{2})$"
        case .cardHolderName:
            return "^([a-zA-Z0-9\\ \\,\\.\\-\\']{2,})$"
        case .cvc:
          return "\\d*$"
        case .none:
          return ""
      }
    }
    
    var keyboardType: UIKeyboardType {
        switch self {
        case .cardNumber, .cvc, .expDate:
            return .numberPad
        default:
            return .alphabet
        }
    }
  
    var defaultValidation: SkyflowValidationSet {
      var rules = SkyflowValidationSet()
      switch self {
      case .cardHolderName:
        rules.add(rule: SkyflowValidatePattern(pattern: self.defaultRegex, error: SkyflowValidationErrorType.pattern.rawValue))
      case .expDate:
        rules.add(rule: SkyflowValidatePattern(pattern: self.defaultRegex, error: SkyflowValidationErrorType.pattern.rawValue))
       // rules.add(rule: SkyflowValidationRuleCardExpirationDate(error: SkyflowValidationErrorType.expDate.rawValue))
      case .cardNumber:
        rules.add(rule: SkyflowValidatePattern(pattern: self.defaultRegex, error: SkyflowValidationErrorType.pattern.rawValue))
        //rules.add(rule: SkyflowValidationRulePaymentCard(error: SkyflowValidationErrorType.cardNumber.rawValue))
      case .cvc:
        rules.add(rule: SkyflowValidatePattern(pattern: self.defaultRegex, error: SkyflowValidationErrorType.pattern.rawValue))
        rules.add(rule: SkyflowValidateLengthMatch(lengths: [3, 4], error: SkyflowValidationErrorType.lengthMathes.rawValue))
      case .none:
        rules = SkyflowValidationSet()
      }
      return rules
    }
  
}

internal enum DateFormatPattern: String {
    case shortYear = "##/##"
    case longYear = "##/####"
}
