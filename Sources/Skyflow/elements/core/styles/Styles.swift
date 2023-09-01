/*
 * Copyright (c) 2022 Skyflow
*/

// An Object that describes states of SkyflowTextField for Style

import Foundation

/// Different styles to apply to a Skyflow element.
public struct Styles {
    var base: Style?
    var complete: Style?
    var empty: Style?
    var focus: Style?
    var invalid: Style?
    var requiredAstrisk: Style?

   /**
    Initializes the styles to apply on a Skyflow element.

    - Parameters:
        - base: Styles applied on skyflow elements in its base form.
        - complete: Styles applied when value is valid.
        - empty: Styles applied when skyflow element is empty.
        - focus: Styles applied when skyflow element is focused.
        - invalid: Styles applied when value is invalid.
        - requiredAstrisk: Styles applied on the required asterisk.
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
