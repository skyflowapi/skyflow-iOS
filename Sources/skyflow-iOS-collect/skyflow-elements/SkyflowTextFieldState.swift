
import Foundation
#if os(iOS)
import UIKit
#endif

public extension SkyflowTextField {

     
    
  
    /// Describes `SkyflowTextField` input   `State`
    var state: State {
        var result: State
        
        /*switch fieldType {
        case .cardNumber:
            result = CardState(tf: self)
        default:
            result = State(tf: self)
        }*/
        result = State(tf: self)
        return result
    }
}

internal extension SkyflowTextField {
  func validate() -> [SkyflowValidationError] {
    let str = textField.getSecureRawText ?? ""
    return SkyflowValidator.validate(input: str, rules: validationRules)
  }
}
