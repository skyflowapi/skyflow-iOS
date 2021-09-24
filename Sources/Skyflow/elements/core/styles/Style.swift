import Foundation
#if os(iOS)
import UIKit
#endif

public struct Style{
    
    var borderColor: UIColor?
    var cornerRadius: CGFloat?
    var padding: UIEdgeInsets?
    var borderWidth: CGFloat?
    var font:  UIFont?
    var textAlignment: NSTextAlignment?
    var textColor: UIColor?
    
    public init(borderColor: UIColor? = nil,
                cornerRadius: CGFloat? = nil,
                padding: UIEdgeInsets? = nil,
                borderWidth: CGFloat? = nil,
                font:  UIFont? = nil,
                textAlignment: NSTextAlignment? = nil,
                textColor: UIColor? = nil) {
        //Assign parametric values to struct members
        self.borderColor = borderColor
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.borderWidth = borderWidth
        self.font = font
        self.textAlignment = textAlignment
        self.textColor = textColor
    }
}
