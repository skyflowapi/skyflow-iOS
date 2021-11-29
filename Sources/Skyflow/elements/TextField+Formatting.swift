
import UIKit

extension TextField {
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string.isEmpty {
            return true
        }
        
        let text = ((textField as! FormatTextField).secureText! as NSString).replacingCharacters(in: range, with: string)

        let count = text.count
        
        if let elementType = self.fieldType.instance {
            
            if let acceptabledCharacters = elementType.acceptableCharacters, string.rangeOfCharacter(from: acceptabledCharacters) == nil {
                return false
            }
            if let maxLength = elementType.maxLength, count > maxLength {
                return false
            }
            
            if !elementType.formatPattern.isEmpty {
                if let replacementText = self.textField.formatText(string) {
                    textField.text = replacementText
                } else {
                    return false
                }
            }
        }

        /* Steps to follow */
        // get type of textfield - done
        // check if type accepts character, length - done
        // yes - check if type has format pattern - done
        //       yes - get text with format pattern (also update actualValue)
        //           - set textField text
        // - return false for all the above
        //
        // return true for no

        return true
    }

}
