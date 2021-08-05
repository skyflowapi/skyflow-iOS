

import Foundation
#if os(iOS)
import UIKit
#endif

internal class StateforText : State
{
    /// true if `SkyflowTextField` input in valid
    internal(set) open var isValid: Bool = false
    
    /// true  if `SkyflowTextField` input is empty
    internal(set) open var isEmpty: Bool = false
  
    /// true if `SkyflowTextField` was edited
    internal(set) open var isDirty: Bool = false
  
    /// represents length of SkyflowTextField
    internal(set) open var inputLength: Int = 0

    /// Array of `SkyflowValidationError`. Should be empty when textfield input is valid.
    internal(set) open var validationErrors =  [SkyflowValidationError]()
    
    init(tf: SkyflowTextField) {
        super.init(columnName: tf.columnName,isRequired: tf.isRequired)
        validationErrors = tf.validate()
        isValid = validationErrors.count == 0
        isEmpty = (tf.textField.getSecureRawText?.count == 0)
        isDirty = tf.isDirty
        inputLength = tf.textField.getSecureRawText?.count ?? 0
    }
    
    /// Message that contains `State` attributes and their values
    public override var show: String {
        var result = ""
        
        guard let columnName = columnName else {
            return "Alias property is empty"
        }
        
        result = """
        "\(columnName)": {
            "isRequired": \(isRequired),
            "isValid": \(isValid),
            "isEmpty": \(isEmpty),
            "isDirty": \(isDirty),
            "validationErrors": \(validationErrors),
            "inputLength": \(inputLength)
        }
        """
        return result
    }
    public override func getState() -> [String:Any]
    {
        var result = [String:Any]()
            result["isRequired"] = isRequired
            result["columnName"] = columnName
            result["isEmpty"] = isEmpty
            result["isDirty"] = isDirty
            result["isValid"] = isValid
            result["inputLength"] = inputLength
            result["validationErrors"] = validationErrors.joined(separator: ",")
        
        return result
    }
}
