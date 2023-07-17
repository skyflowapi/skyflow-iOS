/*
 * Copyright (c) 2022 Skyflow
*/

// An Object that describes Style of SkyflowTextField

import Foundation
#if os(iOS)
import UIKit
#endif

/// This is the description for Style struct.
public struct Style {
    var borderColor: UIColor?
    var cornerRadius: CGFloat?
    var padding: UIEdgeInsets?
    var borderWidth: CGFloat?
    var font: UIFont?
    var textAlignment: NSTextAlignment?
    var textColor: UIColor?

    /**
    This is the description for init method.

    - Parameters:
        - borderColor: This is the description for borderColor parameter.
        - cornerRadius: This is the description for cornerRadius parameter.
        - padding: This is the description for padding parameter.
        - borderWidth: This is the description for borderWidth parameter.
        - font: This is the description for font parameter.
        - textAlignment: This is the description for textAlignment parameter.
        - textColor: This is the description for textColor parameter.
    */
    public init(borderColor: UIColor? = nil,
                cornerRadius: CGFloat? = nil,
                padding: UIEdgeInsets? = nil,
                borderWidth: CGFloat? = nil,
                font: UIFont? = nil,
                textAlignment: NSTextAlignment? = nil,
                textColor: UIColor? = nil) {
        // Assign parametric values to struct members
        self.borderColor = borderColor
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.borderWidth = borderWidth
        self.font = font
        self.textAlignment = textAlignment
        self.textColor = textColor
    }
}
