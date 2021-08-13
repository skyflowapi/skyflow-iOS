import Foundation

#if os(iOS)
import UIKit
#endif


public class SkyflowTextField: SkyflowElement {
    
    internal var textField = FormatTextField(frame: .zero)
    internal var isDirty: Bool = false
    internal var validationRules = SkyflowValidationSet()
  
    /// Describes `SkyflowTextField` input   State`
    internal override var state: State {
        return StateforText(tf: self)
    }
    
    override init(input: CollectElementInput, options: CollectElementOptions) {
        super.init(input: input, options: options)
        setupField()
    }
    
    required internal init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
   
    override func getOutput() -> String? {
            return textField.getTextwithFormatPattern
    }
    
    internal func getOutputTextwithoutFormatPattern() -> String? {
            return textField.getSecureRawText
    }
  
  /// Field Configuration
    override func setupField() {
            super.setupField()
            textField.font = collectInput.styles.base?.font ?? .none
            textField.placeholder = collectInput.placeholder
            textField.textAlignment = collectInput.styles.base?.textAlignment ?? .natural
            textField.textColor = collectInput.styles.base?.textColor ?? .none
            textField.formatPattern = fieldType.instance.formatPattern
            validationRules = fieldType.instance.validation
            textField.keyboardType = fieldType.instance.keyboardType
        
        }
        
    
   override func validate() -> [SkyflowValidationError] {
        let str = textField.getSecureRawText ?? ""
        return SkyflowValidator.validate(input: str, rules: validationRules)
      }
    
}
/// UIResponder methods
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

/// Textfiled delegate
extension SkyflowTextField: UITextFieldDelegate {

     /// Wrap native `UITextField` delegate method for `textFieldDidBeginEditing`.
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        textFieldValueChanged()
        self.textField.textColor = collectInput!.styles.focus?.textColor ?? .none
        borderColor = collectInput!.styles.focus?.borderColor
        
    }
  
    /// Wrap native `UITextField` delegate method for `didChange`.
    @objc func textFieldDidChange(_ textField: UITextField) {
        isDirty = true
        textFieldValueChanged()
        
    }

      /// Wrap native `UITextField` delegate method for `didEndEditing`.
    public func textFieldDidEndEditing(_ textField: UITextField) {
        textFieldValueChanged()
        let state = self.state.getState()
        if(state["isEmpty"] as! Bool)
        {
            self.textField.textColor = collectInput!.styles.empty?.textColor ?? .none
            borderColor = collectInput!.styles.empty?.borderColor
        }
        else if(!(state["isValid"] as! Bool))
        {
            self.textField.textColor = collectInput!.styles.invalid?.textColor ?? .none
            borderColor = collectInput!.styles.invalid?.borderColor
        }
        else
        {
            self.textField.textColor = collectInput!.styles.completed?.textColor ?? .none
            borderColor = collectInput!.styles.completed?.borderColor
        }
        
    }
    
    @objc func textFieldDidEndEditingOnExit(_ textField: UITextField) {
        textFieldValueChanged()
        
    }
}

internal extension SkyflowTextField {
    
   @objc
    override func initialization() {
        super.initialization()
        /// add UI elements
        buildTextFieldUI()
        /// add textfield observers and delegates
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
        /// delegates
        textField.addSomeTarget(self, action: #selector(textFieldDidBeginEditing), for: .editingDidBegin)
        /// Note: .allEditingEvents doesn't work proparly when set text programatically. Use setText instead!
        textField.addSomeTarget(self, action: #selector(textFieldDidEndEditing), for: .editingDidEnd)
        textField.addSomeTarget(self, action: #selector(textFieldDidEndEditingOnExit), for: .editingDidEndOnExit)
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldDidChange), name: UITextField.textDidChangeNotification, object: textField)
        /// tap gesture for update focus state
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(focusOn))
        textField.addGestureRecognizer(tapGesture)
      }
    
  
    @objc
    override func setMainPaddings() {
     
        super.setMainPaddings()
      
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
        /// update format pattern after field input changed
        if self.fieldType == .cardNumber {
            let card = CardType.forCardNumber(cardNumber: getOutput()!)
            if card.defaultName != "Empty"  {
                self.textField.formatPattern = card.formatPattern
              } else {
                self.textField.formatPattern = CardType.UNKNOWN.instance.formatPattern
              }
        }
        textField.updateTextFormat()
    }
  
    /// change focus here
    @objc
    func focusOn() {
        // change status
        textField.becomeFirstResponder()
        textFieldValueChanged()
    }
    
}

