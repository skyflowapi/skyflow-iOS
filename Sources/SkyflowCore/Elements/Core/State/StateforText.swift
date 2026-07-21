/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation
#if os(iOS)
import UIKit
#endif

public class StateforText: State
{
    /// true if `SkyflowTextField` input in valid
    public(set) open var isValid = false

    /// true  if `SkyflowTextField` input is empty
    public(set) open var isEmpty = false

    /// true if `SkyflowTextField` was edited
    public(set) open var isDirty = false

    /// represents length of SkyflowTextField
    public(set) open var inputLength: Int = 0

//    public(set) open var isComplete = false

    public(set) open var isFocused = false

    public(set) open var elementType: ElementType!

    public(set) open var value: String?
    /// Array of `SkyflowValidationError`. Should be empty when textfield input is valid.
    public(set) open var validationError = SkyflowValidationError()
    
    public(set) open var isCustomRuleFailed = false
    public(set) open var isDefaultRuleFailed = false
    public(set) open var selectedCardScheme: CardType?

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
        selectedCardScheme = tf.selectedCardBrand
        if tf.contextOptions.env == .DEV {
            value = tf.actualValue
        } else {
            if tf.fieldType == .CARD_NUMBER {
                // AMEX supports only first 6 characters as BIN
                if CardType.forCardNumber(cardNumber: tf.actualValue) == .AMEX {
                    value = Card.getBIN(tf.actualValue, 6)
                } else {
                    // Default 8 char BIN for all other card types
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
        if elementType == .CARD_NUMBER {
            result["selectedCardScheme"] = selectedCardScheme == nil ? "" : selectedCardScheme?.instance.defaultName.uppercased()
        }
        return result
    }
}
