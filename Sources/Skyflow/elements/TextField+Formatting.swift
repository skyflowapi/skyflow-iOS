
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

        return true
    }
}
