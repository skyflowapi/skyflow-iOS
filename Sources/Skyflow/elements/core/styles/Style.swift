/*
 * Copyright (c) 2022 Skyflow
*/

// An Object that describes Style of SkyflowTextField

import Foundation
#if os(iOS)
import UIKit
#endif

public struct Style {
    var borderColor: UIColor?
    var cornerRadius: CGFloat?
    var padding: UIEdgeInsets?
    var borderWidth: CGFloat?
    var font: UIFont?
    var textAlignment: NSTextAlignment?
    var textColor: UIColor?
    var margin: UIEdgeInsets?
    var boxShadow: CALayer?
    var backgroundColor: UIColor?
    var minWidth: CGFloat?
    var maxWidth: CGFloat?
    var minHeight: CGFloat?
    var maxHeight: CGFloat?
    
    public init(borderColor: UIColor? = nil,
                cornerRadius: CGFloat? = nil,
                padding: UIEdgeInsets? = nil,
                borderWidth: CGFloat? = nil,
                font: UIFont? = nil,
                textAlignment: NSTextAlignment? = nil,
                textColor: UIColor? = nil,
                margin: UIEdgeInsets? = nil,
                boxShadow: CALayer? = nil,
                backgroundColor: UIColor? = nil,
                minWidth: CGFloat? = nil,
                maxWidth: CGFloat? = nil,
                minHeight: CGFloat? = nil,
                maxHeight: CGFloat? = nil
                
    ) {
        // Assign parametric values to struct members
        self.borderColor = borderColor
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.borderWidth = borderWidth
        self.font = font
        self.textAlignment = textAlignment
        self.textColor = textColor
        self.margin = margin
        self.boxShadow = boxShadow
        self.backgroundColor = backgroundColor
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
    }
}
