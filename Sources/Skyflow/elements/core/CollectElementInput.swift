import Foundation

public struct CollectElementInput {
    var table : String
    var column : String
    var styles: Styles
    var labelStyles: Styles
    var errorTextStyles: Styles
    var label : String
    var placeholder:String
    var type : ElementType
    var altText: String?
    
    public init(table: String, column: String,
                styles: Styles? = Styles(), labelStyles: Styles? = Styles(), errorTextStyles: Styles? = Styles(), label: String? = "",
                placeholder: String? = "", type: ElementType, altText: String? = ""){
        
        self.table = table
        self.column = column
        self.styles = styles!
        self.labelStyles = labelStyles!
        self.errorTextStyles = errorTextStyles!
        self.label = label!
        self.placeholder = placeholder!
        self.type = type
        self.altText = altText
    }
}
