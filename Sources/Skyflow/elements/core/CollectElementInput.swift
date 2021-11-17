import Foundation

public struct CollectElementInput {
    var table: String
    var column: String
    var inputStyles: Styles
    var labelStyles: Styles
    var errorTextStyles: Styles
    var label: String
    var placeholder: String
    var type: ElementType
    var altText: String?
    var validations: ValidationSet

    public init(table: String = "", column: String = "",
                inputStyles: Styles? = Styles(), labelStyles: Styles? = Styles(), errorTextStyles: Styles? = Styles(), label: String? = "",
                placeholder: String? = "", type: ElementType, altText: String? = "", validations: ValidationSet=ValidationSet()) {
        self.table = table
        self.column = column
        self.inputStyles = inputStyles!
        self.labelStyles = labelStyles!
        self.errorTextStyles = errorTextStyles!
        self.label = label!
        self.placeholder = placeholder!
        self.type = type
        self.altText = altText
        self.validations = validations
    }
}
