/*
 * Copyright (c) 2022 Skyflow
*/

// An Object that describes states of SkyflowTextField for Style

import Foundation

public struct Styles {
    var base: Style?
    var complete: Style?
    var empty: Style?
    var focus: Style?
    var invalid: Style?
    var requiredAstrisk: Style?

   public init(base: Style? = Style(),
               complete: Style? = Style(),
               empty: Style? =  Style(),
               focus: Style? = Style(),
               invalid: Style? = Style(),
               requiredAstrisk: Style? = Style())
    {
       // Assign parametric values to struct members
        self.base = base
        self.complete = complete
        self.empty = empty
        self.focus = focus
        self.invalid = invalid
        self.requiredAstrisk = requiredAstrisk

   }
}
