//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 12/08/21.
//

import Foundation
import UIKit

public class Label: UIView, Element, BaseElement {
    internal var skyflowLabelView: SkyflowLabelView!
    internal var revealInput: RevealElementInput!
    internal var options: RevealElementOptions!
    internal var stackView = UIStackView()
    internal var labelField = PaddingLabel(frame: .zero)
    internal var errorMessage = PaddingLabel(frame: .zero)
    
    internal var errorTriggered: Bool = false
    internal var triggeredErrorMessage: String = ""


    internal var horizontalConstraints = [NSLayoutConstraint]()

    internal var verticalConstraint = [NSLayoutConstraint]()

    internal init(input: RevealElementInput, options: RevealElementOptions) {
        self.skyflowLabelView = SkyflowLabelView(input: input, options: options)
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

    internal var actualValue: String = ""
    
    internal func updateVal(value: String) {
        self.skyflowLabelView.updateVal(value: value)
        self.actualValue = value
    }

    internal func isMounted() -> Bool {
        var flag = false
        if Thread.isMainThread {
            flag = self.window != nil
        } else {
            DispatchQueue.main.sync {
                flag = self.window != nil
            }
        }
        return flag
    }

    internal func buildLabel() {
        self.translatesAutoresizingMaskIntoConstraints = false

        // Set label base styles
        self.actualValue = self.revealInput.token
        self.labelField.text = self.revealInput.label
        self.labelField.textColor = self.revealInput.labelStyles?.base?.textColor ?? .none
        self.labelField.textAlignment = self.revealInput.labelStyles?.base?.textAlignment ?? .natural
        self.labelField.font = self.revealInput.labelStyles?.base?.font ?? .none
        self.labelField.insets = self.revealInput.labelStyles?.base?.padding ?? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        // Set errorText base styles
        self.errorMessage.alpha = 0.0
        self.errorMessage.textColor = self.revealInput.errorTextStyles?.base?.textColor ?? .none
        self.errorMessage.textAlignment = self.revealInput.errorTextStyles?.base?.textAlignment ?? .natural
        self.errorMessage.font = self.revealInput.errorTextStyles?.base?.font ?? .none
        self.errorMessage.insets = self.revealInput.errorTextStyles?.base?.padding ?? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        self.stackView.axis = .vertical
//        stackView.distribution = .equalSpacing
        self.stackView.spacing = 0
        self.stackView.alignment = .fill
        self.stackView.translatesAutoresizingMaskIntoConstraints = false


        self.stackView.addArrangedSubview(self.labelField)
        self.stackView.addArrangedSubview(self.skyflowLabelView)
        self.stackView.addArrangedSubview(self.errorMessage)

        addSubview(self.stackView)

        setMainPaddings()
    }

    func setMainPaddings() {
        let views = ["view": self, "stackView": stackView]

        verticalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-\(0)-[stackView]-\(0)-|",
                                                            options: .alignAllCenterX,
                                                            metrics: nil,
                                                            views: views)


        horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(0)-[stackView]-\(0)-|",
                                                               options: .alignAllCenterY,
                                                               metrics: nil,
                                                               views: views)
        NSLayoutConstraint.activate(horizontalConstraints)
        NSLayoutConstraint.activate(verticalConstraint)
    }

    func showError(message: String) {
        self.errorMessage.text = message
        self.skyflowLabelView.updateStyle()
        self.errorMessage.alpha = 1.0
    }

    func hideError() {
        if !self.errorTriggered {
            self.errorMessage.alpha = 0.0
        }
    }

    internal func getValue() -> String {
        return self.actualValue
    }
    
    public func setError(_ error: String) {
        self.errorTriggered = true
        self.triggeredErrorMessage = error
        showError(message: error)
    }
    
    public func resetError() {
        self.errorTriggered = false
        hideError()
    }
    
    public func setToken(_ token: String) {
        self.revealInput.token = token
        if self.revealInput.altText.isEmpty {
            self.skyflowLabelView.updateVal(value: token)
        }
    }
    
    public func setAltText(_ altText: String) {
        self.revealInput.altText = altText
        self.skyflowLabelView.updateVal(value: altText)
    }
    
    public func clearAltText() {
        self.revealInput.altText = ""
        self.skyflowLabelView.updateVal(value: actualValue.isEmpty ? revealInput.token : actualValue)
    }
    
    internal func getToken() -> String{
        return self.revealInput.token
    }
}
