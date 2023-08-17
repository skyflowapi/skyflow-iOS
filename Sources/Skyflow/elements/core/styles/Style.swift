/*
 * Copyright (c) 2022 Skyflow
*/

// An Object that describes Style of SkyflowTextField

import Foundation
#if os(iOS)
import UIKit
#endif

/// Contains various styles for Skyflow elements.
public struct Style {
    var borderColor: UIColor?
    var cornerRadius: CGFloat?
    var padding: UIEdgeInsets?
    var borderWidth: CGFloat?
    var font: UIFont?
    var textAlignment: NSTextAlignment?
    var textColor: UIColor?

    /**
    Initializes the styles for Skyflow elements.

    - Parameters:
        - borderColor: Color of the border.
        - cornerRadius: Radius applied to the corners.
        - padding: Padding for the element.
        - borderWidth: Width of the border.
        - font: Type of font used.
        - textAlignment: Alignment of the text.
        - textColor: Color of the text.
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
