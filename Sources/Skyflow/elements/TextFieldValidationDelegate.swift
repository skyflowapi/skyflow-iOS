/*
 * Copyright (c) 2022 Skyflow
*/

// Implementation of Validation delegate for SkyflowTextField

import UIKit


internal class TextFieldValidationDelegate: NSObject, UITextFieldDelegate {
        
    var collectField: TextField
    internal init(collectField: TextField) {
        self.collectField = collectField
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        func updateCursorPosition(offset: Int) {
            if let cursorLoc = textField.position(from: textField.beginningOfDocument, offset: (range.location + string.count+offset)) {
                textField.selectedTextRange = textField.textRange(from: cursorLoc, to: cursorLoc)
            }
        }
        
        func updateFormat(_ text: String, _ isEmpty: Bool = false) -> Bool{
            
            if collectField.fieldType == .EXPIRATION_MONTH {
                if let month = Int(text) {
                    if month == 0 {
                        textField.text = ""
                        self.collectField.updateActualValue()
                        return false
                    }
                }
                return formatMonth()
            }
            
            let formatResult = collectField.textField.formatText(text, range, isEmpty)
            var offset = 0
            
            if formatResult.isSuccess {
                textField.text = formatResult.formattedText
                if range.location == text.count-1{
                    offset = formatResult.numOfSeperatorsAdded
                }
                updateCursorPosition(offset: offset)
                collectField.textFieldDidChange(collectField.textField)
            }
            return false
        }
        
        func formatMonth() -> Bool{
            if let month = Int(text) {
                if month > 1 && month < 10 {
                    textField.text = "0\(month)"
                }
                else if month <= 12 {
                    textField.text = "\(month)"
                }
            }
            self.collectField.onChangeHandler?((collectField.state as! StateforText).getStateForListener())
            self.collectField.updateActualValue()
            return false
        }
        
        let text = ((textField as! FormatTextField).secureText! as NSString).replacingCharacters(in: range, with: string)

        let count = text.count
        
        if string.isEmpty {
            return updateFormat(text, true)
        }
        
        if let elementType = collectField.fieldType.instance {
            
            if let acceptabledCharacters = elementType.acceptableCharacters, string.rangeOfCharacter(from: acceptabledCharacters) == nil {
                return false
            }
            
            if collectField.fieldType == .EXPIRATION_MONTH {
                return formatMonth()
            } else if collectField.fieldType == .EXPIRATION_YEAR {
                if count > collectField.options.format.count {
                    return false
                }
            }
            
            if let maxLength = elementType.maxLength, count > maxLength {
                return false
            }
            
            if !elementType.formatPattern.isEmpty {
                return updateFormat(text)
            }
            
            
        }

        return true
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        collectField.hasFocus = true
        collectField.textFieldValueChanged()
        collectField.updateInputStyle(collectField.collectInput.inputStyles.focus)

        collectField.updateLabelStyle(collectField.collectInput!.labelStyles.focus)
        collectField.resetError()
        collectField.onFocusHandler?((collectField.state as! StateforText).getStateForListener())
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        collectField.hasFocus = false
        if collectField.fieldType == .EXPIRATION_MONTH {
            let text = (textField as! FormatTextField).secureText! as String
            if let month = Int(text) {
                if month == 1 {
                    textField.text = "01"
                }
            }
        }
        
        collectField.updateActualValue()
        collectField.textFieldValueChanged()
        collectField.updateLabelStyle()
        collectField.updateErrorMessage()
        collectField.onBlurHandler?((collectField.state as! StateforText).getStateForListener())
    }
    
    
    @objc func textFieldDidEndEditingOnExit(_ textField: UITextField) {
        collectField.textFieldValueChanged()
    }
    
}
