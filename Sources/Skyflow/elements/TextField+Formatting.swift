
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
        }

        // get type of textfield
        // check if type accepts character
        // yes - get replacement text
        //     - set space/seperator if needed, to textfield.text
        //
        // return false

        return true
    }
//    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        let text = (textField.text! as NSString).replacingCharacters(in: range, with: string)
//
//        let count = text.count
//
//        print("---------",text, text.count)
//        print("=========", string, range)
//
//        // get type of textfield
//        // check if type accepts character
//        // yes - get replacement text
//        //     - set space/seperator if needed, to textfield.text
//        //
//        // return false
//
//        if count > 5 {
//            return false
//        }
//
//        return true
//    }
}
