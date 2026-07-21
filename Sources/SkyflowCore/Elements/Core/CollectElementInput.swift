/*
 * Copyright (c) 2022 Skyflow
*/

// An Object that describes SkyflowInputField

import Foundation

public struct CollectElementInput {
    public var table: String
    public var column: String
    public var inputStyles: Styles
    public var labelStyles: Styles
    public var errorTextStyles: Styles
    public var iconStyles: Styles
    public var label: String
    public var placeholder: String
    public var type: ElementType?
    public var validations: ValidationSet
    public var skyflowID: String

    public init(table: String = "", column: String = "",
                inputStyles: Styles? = Styles(), labelStyles: Styles? = Styles(), errorTextStyles: Styles? = Styles(), iconStyles: Styles? = Styles(), label: String? = "",
                placeholder: String? = "", validations: ValidationSet=ValidationSet(), skyflowID: String? = "") {
        self.table = table
        self.column = column
        self.inputStyles = inputStyles!
        self.labelStyles = labelStyles!
        self.errorTextStyles = errorTextStyles!
        self.iconStyles = iconStyles!
        self.label = label!
        self.placeholder = placeholder!
        self.validations = validations
        self.skyflowID = skyflowID!
    }

    public init(table: String = "", column: String = "",
                inputStyles: Styles? = Styles(), labelStyles: Styles? = Styles(), errorTextStyles: Styles? = Styles(), iconStyles: Styles? = Styles(), label: String? = "",
                placeholder: String? = "", type: ElementType?, validations: ValidationSet=ValidationSet(), skyflowID: String? = "") {
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
        self.skyflowID = skyflowID!
    }
    
    @available(*, deprecated, message: "altText param is deprecated")
    public init(table: String = "", column: String = "",
            inputStyles: Styles? = Styles(), labelStyles: Styles? = Styles(), errorTextStyles: Styles? = Styles(), iconStyles: Styles? = Styles(), label: String? = "",
            placeholder: String? = "", altText: String? = "", type: ElementType?, validations: ValidationSet=ValidationSet(), skyflowID: String? = "") {
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
        self.skyflowID = skyflowID!
    }
}
