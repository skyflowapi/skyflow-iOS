//
//  File.swift
//  
//
//  Created by Tejesh Reddy Allampati on 25/08/21.
//

import Foundation
import UIKit

public class SkyflowLabelView: UIView {
    
    internal var label = FormatLabel(frame: .zero)
    internal var revealInput: RevealElementInput!
    internal var options: RevealElementOptions!
    
    internal var horizontalConstraints = [NSLayoutConstraint]()
    
    internal var verticalConstraint = [NSLayoutConstraint]()
    
    internal func setTextPaddings() {
        NSLayoutConstraint.deactivate(verticalConstraint)
        NSLayoutConstraint.deactivate(horizontalConstraints)
        
        let views = ["view": self, "label": label]
        
        horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(padding.left)-[label]-\(padding.right)-|",
                                                               options: .alignAllCenterY,
                                                               metrics: nil,
                                                               views: views)
        NSLayoutConstraint.activate(horizontalConstraints)
        
        verticalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-\(padding.top)-[label]-\(padding.bottom)-|",
                                                            options: .alignAllCenterX,
                                                            metrics: nil,
                                                            views: views)
        NSLayoutConstraint.activate(verticalConstraint)
        self.layoutIfNeeded()
    }
    
    internal var padding = UIEdgeInsets.zero {
        didSet {
            setTextPaddings()
        }
    }
    
    internal var font: UIFont? {
        get {
            return label.font
        }
        set {
            label.font = newValue
        }
    }
    
    internal var textColor: UIColor? {
        get {
            return label.textColor
        }
        set {
            label.textColor = newValue
        }
    }
    
    internal var textAlignment: NSTextAlignment {
        get {
            return label.textAlignment
        }
        set {
            label.textAlignment = newValue
        }
    }
    
    internal var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    internal var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    internal var borderColor: UIColor? {
        get {
            guard let cgcolor = layer.borderColor else {
                return nil
            }
            return UIColor(cgColor: cgcolor)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    internal init(input: RevealElementInput, options: RevealElementOptions){
        super.init(frame: CGRect())
        self.revealInput = input
        self.options = options
        buildLabel()
    }
    
    override internal init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required internal init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    internal func updateVal(value: String){
        self.label.secureText = value
    }
    
    internal func buildLabel(){
        self.label.secureText = self.revealInput.altText ?? self.revealInput.token
        self.translatesAutoresizingMaskIntoConstraints = false
        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.textAlignment = revealInput.inputStyles?.base?.textAlignment ?? .natural
        self.textColor = revealInput.inputStyles?.base?.textColor ?? .none
        self.borderColor = revealInput.inputStyles?.base?.borderColor ?? .none
        self.cornerRadius = revealInput.inputStyles?.base?.cornerRadius ?? 0
        self.borderWidth = revealInput.inputStyles?.base?.borderWidth ?? 0
        addSubview(self.label)
        self.padding = revealInput.inputStyles?.base?.padding ?? .zero
    }
    
    internal func updateStyle() {
        let style = revealInput.inputStyles?.invalid
        let fallbackStyle = revealInput.inputStyles?.base
        
        self.textAlignment = style?.textAlignment ?? fallbackStyle?.textAlignment ?? .natural
        self.textColor = style?.textColor ?? fallbackStyle?.textColor ?? .none
        self.borderColor = style?.borderColor ?? fallbackStyle?.borderColor ?? .none
        self.cornerRadius = style?.cornerRadius ?? fallbackStyle?.cornerRadius ?? 0
        self.borderWidth = style?.borderWidth ?? fallbackStyle?.borderWidth ?? 0
    }
}
