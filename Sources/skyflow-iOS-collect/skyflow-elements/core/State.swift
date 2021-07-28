

import Foundation
#if os(iOS)
import UIKit
#endif


/// An object that describes `SkyflowTextField` state.  State attributes are read-only.
public class State {
    
    /// `SkyflowConfiguration.fieldName` associated  with `SkyflowTextField`
    internal(set) open var fieldName: String!
    
    /// `SkyflowConfiguration.isRequired` attribute defined for `SkyflowTextField`
    internal(set) open var isRequired: Bool = false
    
    /// Contains current validation state for `SkyflowTextField`
    internal(set) open var isValid: Bool = false
    
    /// Show if `SkyflowTextField` input is empty
    internal(set) open var isEmpty: Bool = false
  
    /// Show if `SkyflowTextField` was edited
    internal(set) open var isDirty: Bool = false
  
    /// Input data length in `SkyflowTextField`
    internal(set) open var inputLength: Int = 0

    /// Array of `SkyflowValidationError`. Should be empty when textfield input is valid.
    internal(set) open var validationErrors =  [SkyflowValidationError]()
    
    init(tf: SkyflowTextField) {
        fieldName = tf.fieldName
        isRequired = tf.isRequired
        validationErrors = tf.validate()
        isValid = validationErrors.count == 0
        isEmpty = (tf.textField.getSecureRawText?.count == 0)
        isDirty = tf.isDirty
        inputLength = tf.textField.getSecureRawText?.count ?? 0
    }
    
    /// Message that contains `State` attributes and their values
    public var description: String {
        var result = ""
        
        guard let fieldName = fieldName else {
            return "Alias property is empty"
        }
        
        result = """
        "\(fieldName)": {
            "isRequired": \(isRequired),
            "isValid": \(isValid),
            "isEmpty": \(isEmpty),
            "isDirty": \(isDirty),
            "inputLength": \(inputLength)
        }
        """
        return result
    }
}

