import Foundation
#if os(iOS)
import UIKit
#endif

public struct SkyflowStyle{
    
    var borderColor: UIColor?
    var cornerRadius: CGFloat?
    var padding: UIEdgeInsets?
    var borderWidth: CGFloat?
    var font:  UIFont?
    var textAlignment: NSTextAlignment?
    var textColor: UIColor?
    
    public init(borderColor: UIColor? = UIColor.lightGray,
                cornerRadius: CGFloat? = 2,
                padding: UIEdgeInsets? = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
                borderWidth: CGFloat? = 2,
                font:  UIFont? = .none,
                textAlignment: NSTextAlignment? = .none,
                textColor: UIColor? = .none) {
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
