/*
 * Copyright (c) 2022 Skyflow
*/

// An Object that describes states of SkyflowTextField for Style

import Foundation

/// This is the description for Styles struct.
public struct Styles {
    var base: Style?
    var complete: Style?
    var empty: Style?
    var focus: Style?
    var invalid: Style?
    var requiredAstrisk: Style?

   /**
    This is the description for init method.

    - Parameters:
        - base: This is the description for base parameter.
        - complete: This is the description for complete parameter.
        - empty: This is the description for empty parameter.
        - focus: This is the description for focus parameter.
        - invalid: This is the description for invalid parameter.
        - requiredAstrisk: This is the description for requiredAstrisk parameter.
    */
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
