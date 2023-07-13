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
    /// This is the description for borderColor property.
    var borderColor: UIColor?
    /// This is the description for cornerRadius property.
    var cornerRadius: CGFloat?
    /// This is the description for padding property.
    var padding: UIEdgeInsets?
    /// This is the description for borderWidth property.
    var borderWidth: CGFloat?
    /// This is the description for font property.
    var font: UIFont?
    /// This is the description for textAlignment property.
    var textAlignment: NSTextAlignment?
    /// This is the description for textColor property.
    var textColor: UIColor?

    /// This is the description for init method.
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
