import Foundation

public struct Styles{
    
    var base: Style?
    var completed: Style?
    var empty: Style?
    var focus: Style?
    var invalid: Style?
   public init(base: Style? = Style(),
               completed: Style? = Style(),
               empty: Style? =  Style(),
               focus: Style? = Style(),
               invalid: Style? = Style()) {
       //Assign parametric values to struct members
        self.base = base
        self.completed = completed
        self.empty = empty
        self.focus = focus
        self.invalid = invalid
   }
}
