/*
 * Copyright (c) 2022 Skyflow
*/

// An Object that describes Style of SkyflowTextField

import Foundation
#if os(iOS)
import UIKit
#endif

public struct Style {
    public var borderColor: UIColor?
    public var cornerRadius: CGFloat?
    public var padding: UIEdgeInsets?
    public var borderWidth: CGFloat?
    public var font: UIFont?
    public var textAlignment: NSTextAlignment?
    public var textColor: UIColor?
    public var boxShadow: CALayer?
    public var backgroundColor: UIColor?
    public var minWidth: CGFloat?
    public var maxWidth: CGFloat?
    public var minHeight: CGFloat?
    public var maxHeight: CGFloat?
    public var cursorColor: UIColor?
    public var width: CGFloat?
    public var height: CGFloat?
    public var placeholderColor: UIColor?
    public var cardIconAlignment: CardIconAlignment?
//    public var margin: UIEdgeInsets?

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
