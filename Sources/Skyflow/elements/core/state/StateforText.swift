/*
 * Copyright (c) 2022 Skyflow
 */

import Foundation
#if os(iOS)
import UIKit
#endif

internal class StateforText: State {
    internal(set) open var isValid = false
    internal(set) open var isEmpty = false
    internal(set) open var isDirty = false
    internal(set) open var inputLength: Int = 0
    internal(set) open var isFocused = false
    internal(set) open var elementType: ElementType!
    internal(set) open var value: String?
    internal(set) open var validationError = SkyflowValidationError()
    internal(set) open var isCustomRuleFailed = false
    internal(set) open var isDefaultRuleFailed = false

    init(tf: TextField) {
        super.init(columnName: tf.columnName, isRequired: tf.isRequired)
        validationError = tf.validate()
        isDefaultRuleFailed = validationError.count != 0
        let customError = tf.validateCustomRules()
        isCustomRuleFailed = customError.count != 0
        isValid = !(isDefaultRuleFailed || isCustomRuleFailed)
        isEmpty = (tf.textField.getSecureRawText?.count == 0)
        isDirty = tf.isDirty
        inputLength = tf.textField.getSecureRawText?.count ?? 0
        elementType = tf.collectInput.type
        isFocused = tf.hasFocus
        if tf.contextOptions.env == .DEV {
            value = tf.actualValue
        } else {
            if tf.fieldType == .CARD_NUMBER {
                if CardType.forCardNumber(cardNumber: tf.actualValue) == .AMEX {
                    value = Card.getBIN(tf.actualValue, 6)
                } else {
                    value = Card.getBIN(tf.actualValue)
                }
            }
        }
        if validationError.count == 0 {
            validationError = customError
        }
    }

    public override func getState() -> [String: Any] {
        var result = [String: Any]()
        result["isRequired"] = isRequired
        result["columnName"] = columnName
        result["isEmpty"] = isEmpty
        result["isDirty"] = isDirty
        result["isValid"] = isValid
        result["inputLength"] = inputLength
        result["validationError"] = validationError
        result["isCustomRuleFailed"] = isCustomRuleFailed
        result["isDefaultRuleFailed"] = isDefaultRuleFailed
        return result
    }

    public func getStateForListener() -> [String: Any] {
        var result = [String: Any]()
        result["isEmpty"] = isEmpty
        result["isValid"] = isValid
        result["elementType"] = elementType
        result["isFocused"] = isFocused
        result["value"] = value == nil ? "" : value
        result["isCustomRuleFailed"] = isCustomRuleFailed
        return result
    }
}
