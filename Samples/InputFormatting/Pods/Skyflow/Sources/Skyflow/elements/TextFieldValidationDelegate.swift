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
                    collectField.onBeginEditing?()
                }
                else if month <= 12 {
                    textField.text = "\(month)"
                    if( month == 11 || month == 12 || month == 10){
                        collectField.onBeginEditing?()
                    }
                }
            }
            self.collectField.updateActualValue()
            if(text.count <= 2){
                collectField.onChangeHandler?((collectField.state as! StateforText).getStateForListener())
            }
            return false
        }
        func customFormat() -> Bool {
            if(collectField.options.translation == nil){
                collectField.options.translation = ["X": "[0-9]"]
            }
            for (key, value) in collectField.options.translation! {
                if value == "" {
                    collectField.options.translation![key] = "(?:)"
                }
            }
            if (collectField.options.format.count >= text.count) {
                let formattedResult = collectField.textField.formatInput(input: text, format: collectField.options.format, translation: collectField.options.translation!)
                textField.text = formattedResult
                updateCursorPosition(offset: formattedResult.count)
                collectField.textFieldDidChange(collectField.textField)
            }

            return false
        }
        let text = ((textField as! FormatTextField).secureText! as NSString).replacingCharacters(in: range, with: string)
        let count = text.count
        if collectField.fieldType == .EXPIRATION_MONTH {
            if collectField.options.enableCopy && (text != "0" && text.count > 0) {
                collectField.textField.rightViewMode = .always
                collectField.textField.rightView?.isHidden = false
            } else if collectField.options.enableCopy {
                collectField.textField.rightViewMode = .always
                collectField.textField.rightView?.isHidden = true
            }
        }
        if string.isEmpty {
            if (collectField.fieldType == .EXPIRATION_MONTH){
                (textField as! FormatTextField).secureText = ""
            }
            return updateFormat(text, true)
        }
        if (collectField.fieldType == .INPUT_FIELD && !(collectField.options.format == "mm/yy" || collectField.options.format == "")) {
            return customFormat()
         }
        if let elementType = collectField.fieldType.instance {       
            if let acceptabledCharacters = elementType.acceptableCharacters, string.rangeOfCharacter(from: acceptabledCharacters) == nil {
                return false
            }
            
            if collectField.fieldType == .EXPIRATION_MONTH && text.count <= 2 {
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
//        collectField.onEndEditing?()
    }
   public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
       collectField.onSubmitHandler?()
       return true
       }
    
    @objc func textFieldDidEndEditingOnExit(_ textField: UITextField) {
        collectField.textFieldValueChanged()
    }
    
}
