import Foundation

public struct CollectElementInput {
    var table : String
    var column : String
    var styles: SkyflowStyles
    var label : String
    var placeholder:String
    var type : SkyflowElementType
    public init(table: String, column: String,
                styles: SkyflowStyles? = SkyflowStyles(), label: String? = "",
                placeholder: String? = "", type: SkyflowElementType){
        
            self.table = table
            self.column = column
            self.styles = styles!
            self.label = label!
            self.placeholder = placeholder!
            self.type = type
  }
}
