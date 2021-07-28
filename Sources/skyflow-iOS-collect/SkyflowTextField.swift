//
//  SkyflowTextField.swift
//  demo
//
//  Created by Santhosh Kamal Murthy Yennam on 22/07/21.
//


import Foundation

#if os(iOS)
import UIKit
#endif


public class SkyflowTextField: UIView, SkyflowField {
    
    internal var textField = MaskedTextField(frame: .zero)
    internal var focusStatus: Bool = false
    internal var isRequired: Bool = false
    internal var isDirty: Bool = false
    internal var fieldType: FieldType = .none
    internal var fieldName: String!
    internal var token: String?
    internal var horizontalConstraints = [NSLayoutConstraint]()
    internal var verticalConstraint = [NSLayoutConstraint]()
    internal var validationRules = SkyflowValidationSet()

    internal(set) var tableName: String?
    internal(set) var columnName: String?
    
    /// Textfield placeholder string.
    public var placeholder: String? {
        didSet { textField.placeholder = placeholder }
    }
    
    /// Textfield attributedPlaceholder string.
    public var attributedPlaceholder: NSAttributedString? {
        didSet {
            textField.attributedPlaceholder = attributedPlaceholder
        }
    }
    
    public var padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) {
        didSet { setMainPaddings() }
    }
    
    /// The technique to use for aligning the text.
    public var textAlignment: NSTextAlignment = .natural {
        didSet { textField.textAlignment = textAlignment }
    }
    
    /// Sets when the clear button shows up. Default is `UITextField.ViewMode.never`
    public var clearButtonMode: UITextField.ViewMode = .never {
      didSet { textField.clearButtonMode = clearButtonMode }
    }
  
    /// Identifies whether the text object should disable text copying and in some cases hide the text being entered. Default is false.
    public var isSecureTextEntry: Bool = false {
        didSet { textField.isSecureTextEntry = isSecureTextEntry }
    }
  
    /// Indicates whether `SkyflowTextField ` should automatically update its font when the device’s `UIContentSizeCategory` is changed.
   /* public var adjustsFontForContentSizeCategory: Bool = false {
        didSet { textField.adjustsFontForContentSizeCategory = adjustsFontForContentSizeCategory }
    }*/
    
    /// Input Accessory View
    public var keyboardAccessoryView: UIView? {
      didSet { textField.inputAccessoryView = keyboardAccessoryView }
    }
  
  
    
    /// Specifies `SkyflowTextField` configuration parameters to work with `SkyflowCollect`.
    public var configuration: SkyflowConfiguration? {
        didSet {
          setupField(with: configuration!)
        }
    }
    
    /// Delegates `SkyflowTextField` editing events. Default is `nil`.
    public weak var delegate: SkyflowTextFieldDelegate?
    
    // MARK: - Init
    override internal init(frame: CGRect) {
        super.init(frame: frame)
        mainInitialization()
    }
    
    required internal init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        mainInitialization()
    }
    
//    internal init(){
//        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
//        print("init")
//    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
  
  
    /// Set textfield default text.
    /// - Note: This will not change `State.isDirty` attribute.
    /// - Discussion: probably you should want to set field configuration before setting default value, so the input format will be update as required.
    public func setDefaultText(_ text: String?) {
      updateTextFieldInput(text)
    }
  
    /// :nodoc: Set textfield text.
    public func setText(_ text: String?) {
      isDirty = true
      updateTextFieldInput(text)
    }

    /// Removes input from field.
    public func cleanText() {
      updateTextFieldInput("")
    }
  

  internal func getOutputText() -> String? {
        return textField.getSecureTextWithDivider
  }
    
  internal func getValue() -> Any {
        return getOutputText()
    }
  
  /// Field Configuration
  internal func setupField(with configuration: SkyflowConfiguration) {
    // config text field
    fieldName = configuration.fieldName
    isRequired = configuration.isRequired
    fieldType = configuration.type
    textField.keyboardType = configuration.keyboardType ?? configuration.type.keyboardType
    textField.keyboardType = UIKeyboardType.alphabet
    textField.returnKeyType = configuration.returnKeyType ?? .default
    textField.keyboardAppearance = configuration.keyboardAppearance ?? .default
    
    if let pattern = configuration.formatPattern {
        textField.formatPattern = pattern
    } else {
            textField.formatPattern = configuration.type.defaultFormatPattern
    }
    
    
  
    /// Validation
    if let rules = configuration.validationRules {
      validationRules = rules
    } else {
      validationRules = fieldType.defaultValidation
    }
  }

}
// MARK: - UIResponder methods
extension SkyflowTextField {
    
    /// Make `SkyflowTextField` focused.
    @discardableResult override public func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }
    
    /// Remove  focus from `SkyflowTextField`.
    @discardableResult override public func resignFirstResponder() -> Bool {
        return textField.resignFirstResponder()
    }
    
    /// Check if `SkyflowTextField` is focused.
    override public var isFirstResponder: Bool {
        return textField.isFirstResponder
    }
}

// MARK: - Textfiled delegate
extension SkyflowTextField: UITextFieldDelegate {

     /// :nodoc: Wrap native `UITextField` delegate method for `textFieldDidBeginEditing`.
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        textFieldValueChanged()
        delegate?.SkyflowTextFieldDidBeginEditing?(self)
    }
  
    @objc func textFieldDidChange(_ textField: UITextField) {
        isDirty = true
        textFieldValueChanged()
        delegate?.SkyflowTextFieldDidChange?(self)
    }

      /// :nodoc: Wrap native `UITextField` delegate method for `didEndEditing`.
    public func textFieldDidEndEditing(_ textField: UITextField) {
        textFieldValueChanged()
        delegate?.SkyflowTextFieldDidEndEditing?(self)
    }
    
    @objc func textFieldDidEndEditingOnExit(_ textField: UITextField) {
        textFieldValueChanged()
        delegate?.SkyflowTextFieldDidEndEditingOnReturn?(self)
    }
}

// MARK: - private API
internal extension SkyflowTextField {
    
    @objc
    func mainInitialization() {
        // set main style for view
        mainStyle()
        // add UI elements
        buildTextFieldUI()
        // add otextfield observers and delegates
        addTextFieldObservers()
    }
  
    @objc
    func buildTextFieldUI() {
        textField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textField)
        setMainPaddings()
    }
  
    @objc
      func addTextFieldObservers() {
        //delegates
        textField.addSomeTarget(self, action: #selector(textFieldDidBeginEditing), for: .editingDidBegin)
        //Note: .allEditingEvents doesn't work proparly when set text programatically. Use setText instead!
        textField.addSomeTarget(self, action: #selector(textFieldDidEndEditing), for: .editingDidEnd)
        textField.addSomeTarget(self, action: #selector(textFieldDidEndEditingOnExit), for: .editingDidEndOnExit)
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldDidChange), name: UITextField.textDidChangeNotification, object: textField)
        // tap gesture for update focus state
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(focusOn))
        textField.addGestureRecognizer(tapGesture)
      }
    
  
    @objc
    func setMainPaddings() {
      NSLayoutConstraint.deactivate(verticalConstraint)
      NSLayoutConstraint.deactivate(horizontalConstraints)
      
      let views = ["view": self, "textField": textField]
        
      horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(padding.left)-[textField]-\(padding.right)-|",
                                                                   options: .alignAllCenterY,
                                                                   metrics: nil,
                                                                   views: views)
      NSLayoutConstraint.activate(horizontalConstraints)
        
      verticalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-\(padding.top)-[textField]-\(padding.bottom)-|",
                                                                options: .alignAllCenterX,
                                                                metrics: nil,
                                                                views: views)
      NSLayoutConstraint.activate(verticalConstraint)
      self.layoutIfNeeded()
    }

    @objc
    func textFieldValueChanged() {
        // update format pattern after field input changed
        updateFormatPattern()
//        print("text value: "+getOutputText()!)
    }
  
  func updateFormatPattern() {
    textField.updateTextFormat()
  }
    
    // change focus here
    @objc
    func focusOn() {
        // change status
        textField.becomeFirstResponder()
        textFieldValueChanged()
    }
  
  /// This will update format pattern and notify about the change
  func updateTextFieldInput(_ text: String?) {
    
  }
}

// MARK: - Main style for text field
extension UIView {
    func mainStyle() {
        layer.borderColor = UIColor.lightGray.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 4
    }
}
