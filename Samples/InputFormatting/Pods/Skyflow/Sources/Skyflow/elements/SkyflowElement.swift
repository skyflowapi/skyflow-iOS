/*
 * Copyright (c) 2022 Skyflow
*/

// Implementation of SkyflowElement

import Foundation

#if os(iOS)
import UIKit
#endif


public class SkyflowElement: UIView {
    internal var isRequired = false
    internal var fieldType: ElementType!
    internal var columnName: String!
    internal var tableName: String?
    internal var horizontalConstraints = [NSLayoutConstraint]()
    internal var verticalConstraint = [NSLayoutConstraint]()
    internal var collectInput: CollectElementInput!
    internal var options: CollectElementOptions!
    internal var contextOptions: ContextOptions!
    internal var elements: [TextField] = []

    /// Describes `SkyflowElement` input   State`
    internal var state: State {
        return State(columnName: self.columnName, isRequired: self.isRequired)
    }

    internal func getState() -> [String: Any] {
        return state.getState()
    }

    override internal init(frame: CGRect) {
        super.init(frame: frame)
        initialization()
    }

    internal init(input: CollectElementInput, options: CollectElementOptions, contextOptions: ContextOptions, elements: [TextField]) {
        super.init(frame: CGRect())
        self.elements = elements
        collectInput = input
        self.options = options
        self.contextOptions = contextOptions
        setupField()
        initialization()
    }

    required internal init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialization()
    }


    deinit {
        NotificationCenter.default.removeObserver(self)
    }

  /// Field Configuration
    internal func setupField() {
            tableName = collectInput.table
            columnName = collectInput.column
            fieldType = collectInput.type
            isRequired = options.required
      }

    internal func getOutput() -> String? {
            return ""
    }


   internal func validate() -> SkyflowValidationError {
        return SkyflowValidationError()
      }
   internal var padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) {
        didSet { setMainPaddings() }
    }
}

public extension SkyflowElement {
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

     override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
    }
}

internal extension SkyflowElement {
    @objc
     func initialization() {
        mainStyle()
    }

    @objc
    func setMainPaddings() {
      NSLayoutConstraint.deactivate(verticalConstraint)
      NSLayoutConstraint.deactivate(horizontalConstraints)
    }
}

extension UIView {
    func mainStyle() {
        clipsToBounds = true
    }
}
