/*
 * Copyright (c) 2022 Skyflow
*/

// An Object that describes SkyflowInputField

import Foundation

/// This is the description for CollectElementInput struct.
public struct CollectElementInput {
    /// This is the description for table property.
    var table: String
    /// This is the description for column property.
    var column: String
    /// This is the description for inputStyles property.
    var inputStyles: Styles
    /// This is the description for labelStyles property.
    var labelStyles: Styles
    /// This is the description for errorTextStyles property.
    var errorTextStyles: Styles
    /// This is the description for iconStyles property.
    var iconStyles: Styles
    /// This is the description for label property.
    var label: String
    /// This is the description for placeholder property.
    var placeholder: String
    /// This is the description for type property.
    var type: ElementType
    /// This is the description for validations property.
    var validations: ValidationSet
    
    /// This is the description for init method.
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
