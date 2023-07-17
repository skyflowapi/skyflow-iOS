/*
 * Copyright (c) 2022 Skyflow
*/

// An Object that describes SkyflowInputField

import Foundation

/// This is the description for CollectElementInput struct.
public struct CollectElementInput {
    var table: String
    var column: String
    var inputStyles: Styles
    var labelStyles: Styles
    var errorTextStyles: Styles
    var iconStyles: Styles
    var label: String
    var placeholder: String
    var type: ElementType
    var validations: ValidationSet
    
    /**
    This is the description for init method.

    - Parameters:
        - table: This is the description for table parameter.
        - column: This is the description for column parameter.
        - inputStyles: This is the description for inputStyles parameter.
        - labelStyles: This is the description for labelStyles parameter.
        - errorTextStyles: This is the description for errorTextStyles parameter.
        - iconStyles: This is the description for iconStyles parameter.
        - label: This is the description for label parameter.
        - placeholder: This is the description for placeholder parameter.
        - type: This is the description for type parameter.
        - validations: This is the description for validations parameter.
    */
    public init(table: String = "", column: String = "",
                inputStyles: Styles? = Styles(), labelStyles: Styles? = Styles(), errorTextStyles: Styles? = Styles(), iconStyles: Styles? = Styles(), label: String? = "",
                placeholder: String? = "", type: ElementType, validations: ValidationSet=ValidationSet()) {
        self.table = table
        self.column = column
        self.inputStyles = inputStyles!
        self.labelStyles = labelStyles!
        self.errorTextStyles = errorTextStyles!
        self.iconStyles = iconStyles!
        self.label = label!
        self.placeholder = placeholder!
        self.type = type
        self.validations = validations
    }

    @available(*, deprecated, message: "altText param is deprecated")
    public init(table: String = "", column: String = "",
            inputStyles: Styles? = Styles(), labelStyles: Styles? = Styles(), errorTextStyles: Styles? = Styles(), iconStyles: Styles? = Styles(), label: String? = "",
            placeholder: String? = "", altText: String? = "", type: ElementType, validations: ValidationSet=ValidationSet()) {
        self.table = table
        self.column = column
        self.inputStyles = inputStyles!
        self.labelStyles = labelStyles!
        self.errorTextStyles = errorTextStyles!
        self.iconStyles = iconStyles!
        self.label = label!
        self.placeholder = placeholder!
        self.type = type
        self.validations = validations
    }
}
