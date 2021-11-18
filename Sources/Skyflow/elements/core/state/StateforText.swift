import Foundation
#if os(iOS)
import UIKit
#endif

internal class StateforText: State
{
    /// true if `SkyflowTextField` input in valid
    internal(set) open var isValid = false

    /// true  if `SkyflowTextField` input is empty
    internal(set) open var isEmpty = false

    /// true if `SkyflowTextField` was edited
    internal(set) open var isDirty = false

    /// represents length of SkyflowTextField
    internal(set) open var inputLength: Int = 0

//    internal(set) open var isComplete = false

    internal(set) open var isFocused = false

    internal(set) open var elementType: ElementType!

    internal(set) open var value: String?
    /// Array of `SkyflowValidationError`. Should be empty when textfield input is valid.
    internal(set) open var validationError = SkyflowValidationError()

    init(tf: TextField) {
        super.init(columnName: tf.columnName, isRequired: tf.isRequired)
        validationError = tf.validate()
        isValid = validationError.count == 0
        isEmpty = (tf.textField.getSecureRawText?.count == 0)
        isDirty = tf.isDirty
        inputLength = tf.textField.getSecureRawText?.count ?? 0
        elementType = tf.collectInput.type
//        isComplete = validationErrors.count == 0
        isFocused = tf.hasFocus
        if tf.contextOptions.env == .DEV {
            value = tf.actualValue
        }
    }

    /// Message that contains `State` attributes and their values
//    public override var show: String {
//        var result = ""
//
//        guard let columnName = columnName else {
//            return "Alias property is empty"
//        }
//
//        result = """
//        "\(columnName)": {
//            "isValid": \(isValid),
//            "isEmpty": \(isEmpty),
//        }
//        """
//        return result
//    }

    public override func getState() -> [String: Any] {
        var result = [String: Any]()
            result["isRequired"] = isRequired
            result["columnName"] = columnName
            result["isEmpty"] = isEmpty
            result["isDirty"] = isDirty
            result["isValid"] = isValid
            result["inputLength"] = inputLength
            result["validationError"] = validationError

        return result
    }

    public func getStateForListener() -> [String: Any] {
        var result = [String: Any]()
            result["isEmpty"] = isEmpty
            result["isValid"] = isValid
            result["elementType"] = elementType
            result["isFocused"] = isFocused
            result["value"] = value == nil ? "" : value
        return result
    }
}
