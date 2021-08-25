import Foundation

public struct CollectElementInput {
    var table : String
    var column : String
    var styles: Styles
    var label : String
    var placeholder:String
    var type : ElementType
    public init(table: String, column: String,
                styles: Styles? = Styles(), label: String? = "",
                placeholder: String? = "", type: ElementType){
        
            self.table = table
            self.column = column
            self.styles = styles!
            self.label = label!
            self.placeholder = placeholder!
            self.type = type
  }
}
