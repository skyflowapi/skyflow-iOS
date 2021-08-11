import Foundation

public struct SkyflowStyles{
    
    var base: SkyflowStyle?
    var completed: SkyflowStyle?
    var empty: SkyflowStyle?
    var focus: SkyflowStyle?
    var invalid: SkyflowStyle?
   public init(base: SkyflowStyle? = SkyflowStyle(),
               completed: SkyflowStyle? = SkyflowStyle(),
               empty: SkyflowStyle? =  SkyflowStyle(),
               focus: SkyflowStyle? = SkyflowStyle(),
               invalid: SkyflowStyle? = SkyflowStyle()) {
       //Assign parametric values to struct members
        self.base = base
        self.completed = completed
        self.empty = empty
        self.focus = focus
        self.invalid = invalid
   }
}
