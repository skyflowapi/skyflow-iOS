/*
 * Copyright (c) 2022 Skyflow
*/

// Implementation of SkyflowElement

import Foundation

#if os(iOS)
import UIKit
#endif


public class SkyflowElement: UIView {
    public var isRequired = false
    public var fieldType: ElementType!
    public var columnName: String!
    public var tableName: String?
    public var skyflowID: String?
    public var horizontalConstraints = [NSLayoutConstraint]()
    public var verticalConstraint = [NSLayoutConstraint]()
    public var collectInput: CollectElementInput!
    public var options: CollectElementOptions!
    public var contextOptions: ContextOptions!
    public var elements: [TextField] = []

    /// Describes `SkyflowElement` input   State`
    public var state: State {
        return State(columnName: self.columnName, isRequired: self.isRequired)
    }

    public func getState() -> [String: Any] {
        return state.getState()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialization()
    }

    public init(input: CollectElementInput, options: CollectElementOptions, contextOptions: ContextOptions, elements: [TextField]) {
        super.init(frame: CGRect())
        self.elements = elements
        collectInput = input
        self.options = options
        self.contextOptions = contextOptions
        setupField()
        initialization()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialization()
    }


    deinit {
        NotificationCenter.default.removeObserver(self)
    }

  /// Field Configuration
    public func setupField() {
            tableName = collectInput.table
            columnName = collectInput.column
            fieldType = collectInput.type
            isRequired = options.required
            skyflowID = collectInput.skyflowID
      }

    public func getOutput() -> String? {
            return ""
    }


   public func validate() -> SkyflowValidationError {
        return SkyflowValidationError()
      }
   public var padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) {
        didSet { setMainPaddings() }
    }
}

public extension SkyflowElement {
      public var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }

    public var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }

    public var borderColor: UIColor? {
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

public extension SkyflowElement {
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
