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
    var boxShadow: CALayer?
    var backgroundColor: UIColor?
    var minWidth: CGFloat?
    var maxWidth: CGFloat?
    var minHeight: CGFloat?
    var maxHeight: CGFloat?
    var cursorColor: UIColor?
    var width: CGFloat?
    var height: CGFloat?
    var placeholderColor: UIColor?
    var cardIconAlignment: CardIconAlignment?
//    var margin: UIEdgeInsets?

    public init(borderColor: UIColor? = nil,
                cornerRadius: CGFloat? = nil,
                padding: UIEdgeInsets? = nil,
                borderWidth: CGFloat? = nil,
                font: UIFont? = nil,
                textAlignment: NSTextAlignment? = nil,
                textColor: UIColor? = nil,
                boxShadow: CALayer? = nil,
                backgroundColor: UIColor? = nil,
                minWidth: CGFloat? = nil,
                maxWidth: CGFloat? = nil,
                minHeight: CGFloat? = nil,
                maxHeight: CGFloat? = nil,
                cursorColor: UIColor? = nil,
                width: CGFloat? = nil,
                height: CGFloat? = nil,
                placeholderColor: UIColor? = nil,
                cardIconAlignment: CardIconAlignment? = .left
//                margin: UIEdgeInsets? = nil
    ) {
        // Assign parametric values to struct members
        self.borderColor = borderColor
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.borderWidth = borderWidth
        self.font = font
        self.textAlignment = textAlignment
        self.textColor = textColor
        self.boxShadow = boxShadow
        self.backgroundColor = backgroundColor
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.cursorColor = cursorColor
        self.width = width
        self.height = height
        self.placeholderColor = placeholderColor
        self.cardIconAlignment = cardIconAlignment
//        self.margin = margin
    }
}
