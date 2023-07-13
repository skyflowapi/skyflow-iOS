/*
 * Copyright (c) 2022 Skyflow
*/

// An Object that describes states of SkyflowTextField for Style

import Foundation

/// This is the description for Styles struct.
public struct Styles {
    /// This is the description for base property.
    var base: Style?
    /// This is the description for complete property.
    var complete: Style?
    /// This is the description for empty property.
    var empty: Style?
    /// This is the description for focus property.
    var focus: Style?
    /// This is the description for invalid property.
    var invalid: Style?
    /// This is the description for requiredAstrisk property.
    var requiredAstrisk: Style?

   /// This is the description for init method.
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
