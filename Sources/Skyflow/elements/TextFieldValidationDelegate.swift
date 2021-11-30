import UIKit


internal class TextFieldValidationDelegate: NSObject, UITextFieldDelegate {
        
    var collectField: TextField
    internal init(collectField: TextField) {
        self.collectField = collectField
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string.isEmpty {
            return true
        }
        
        let text = ((textField as! FormatTextField).secureText! as NSString).replacingCharacters(in: range, with: string)

        let count = text.count
        
        if let elementType = collectField.fieldType.instance {
            
            if let acceptabledCharacters = elementType.acceptableCharacters, string.rangeOfCharacter(from: acceptabledCharacters) == nil {
                return false
            }
            if let maxLength = elementType.maxLength, count > maxLength {
                return false
            }
            
            if !elementType.formatPattern.isEmpty {
                if let replacementText = collectField.textField.formatText(string) {
                    textField.text = replacementText
                } else {
                    return false
                }
            }
        }

        return true
    }

    /// Wrap native `UITextField` delegate method for `textFieldDidBeginEditing`.
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        collectField.hasFocus = true
        collectField.textFieldValueChanged()
        // element styles on focus
        collectField.updateInputStyle(collectField.collectInput.inputStyles.focus)

        // label styles on focus
        collectField.updateLabelStyle(collectField.collectInput!.labelStyles.focus)
        collectField.onFocusHandler?((collectField.state as! StateforText).getStateForListener())
    }
    
    /// Wrap native `UITextField` delegate method for `didEndEditing`.
    public func textFieldDidEndEditing(_ textField: UITextField) {
        collectField.hasFocus = false
        collectField.updateActualValue()
        collectField.textFieldValueChanged()

        // Set label styles to base
        collectField.updateLabelStyle()
        collectField.updateErrorMessage()
        collectField.onBlurHandler?((collectField.state as! StateforText).getStateForListener())
    }
    
    
    @objc func textFieldDidEndEditingOnExit(_ textField: UITextField) {
        collectField.textFieldValueChanged()
    }
    
}
