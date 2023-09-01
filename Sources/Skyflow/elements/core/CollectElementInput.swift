/*
 * Copyright (c) 2022 Skyflow
*/

// An Object that describes SkyflowInputField

import Foundation

/// Configuration for a Collect Element.
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
    Initializes the Collect element input.

    - Parameters:
        - table: Table that the data belongs to.
        - column: Column that the data belongs to.
        - inputStyles: Styles for the element.
        - labelStyles: Styles for the element's label.
        - errorTextStyles: Styles for the element's error text.
        - iconStyles: Styles for the element's icon.
        - label: Label for the element.
        - placeholder: Placeholder text for the element.
        - type: Type of the element.
        - validations: Input validation rules for the element.
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
