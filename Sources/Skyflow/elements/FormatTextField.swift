#if os(iOS)
import UIKit
#endif

///  textfield used in SkyflowTextField
internal class FormatTextField: UITextField {
    enum FormatPatternChar: String, CaseIterable {
        case lettersAndDigit = "*"
        case anyLetter = "@"
        case lowerCaseLetter = "a"
        case upperCaseLetter = "A"
        case digits = "#"
    }

    /**
     formatPattern: "#### #### #### ####"
     If the pattern is set to "" no mask would be applied and
     the textfield would remain same
     */
    var formatPattern: String = ""

    /** used for text with format pattern*/
    var textwithFormatPattern = ""


    /**
     Var that have the maximum length, based on the mask set
     */
    var maxLength: Int {
        get {
            return formatPattern.count
        }
        set { }
    }

    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
      var textRect = super.leftViewRect(forBounds: bounds)
        textRect.origin.x += padding.left - 35
      return textRect
    }
    
    
    /**
     Overriding the var text from UITextField so if any text
     is applied programmatically by calling formatText
     */
    @available(*, deprecated, message: "Don't use this method.")
    override var text: String? {
        set {
            secureText = newValue
        }
        get { return nil }
    }

    /// text just for internal using
    internal var secureText: String? {
        set {
            super.text = newValue
            self.updateTextFormat()
        }
        get {
            return super.text
        }
    }

    /** returns textfield text without mask (format pattern) */
    internal var getSecureRawText: String? {
        return getRawText()
    }

    /** returns text with format pattern*/
    internal var getTextwithFormatPattern: String? {
        return formatPattern.isEmpty ? secureText : textwithFormatPattern
    }

    internal var padding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    override open func textRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    override open func editingRect(forBounds bounds: CGRect) -> CGRect {
        return bounds.inset(by: padding)
    }

    func updateTextFormat() {
        self.undoManager?.removeAllActions()
        //self.formatText()
    }
//
//    private func getOnlyDigitsString(_ string: String) -> String {
//        let charactersArray = string.components(separatedBy: CharacterSet.SkyflowAsciiDecimalDigits.inverted)
//        return charactersArray.joined(separator: "")
//    }
//
//    private func getOnlyLettersString(_ string: String) -> String {
//        let charactersArray = string.components(separatedBy: CharacterSet.letters.inverted)
//        return charactersArray.joined(separator: "")
//    }

//    private func getUppercaseLettersString(_ string: String) -> String {
//        let charactersArray = string.components(separatedBy: CharacterSet.uppercaseLetters.inverted)
//        return charactersArray.joined(separator: "")
//    }
//
//    private func getLowercaseLettersString(_ string: String) -> String {
//        let charactersArray = string.components(separatedBy: CharacterSet.lowercaseLetters.inverted)
//        return charactersArray.joined(separator: "")
//    }

    private func getFilteredString(_ string: String) -> String {
        let charactersArray = string.components(separatedBy: CharacterSet.alphanumerics.inverted)
        return charactersArray.joined(separator: "")
    }

    private func getRawText() -> String? {
        guard let text = secureText else {
            return nil
        }
        return formatPattern.isEmpty ? secureText : getFilteredString(text)
    }


    private func getText(_ string: String) -> String {
            return string
    }

    /**
     Func that formats the text based on formatPattern
     */
    func formatText(_ replacementString: String) -> String? {
        if self.formatPattern.isEmpty {
            return ""
        }
        
        var formattedText = ""
        
        var offset = 0
        
        if let text = super.text {
            
            if text.count >= formatPattern.count {
                return nil
            }
            
            if text.count > 0 {
                var filteredText  = self.getFilteredString(text)
                filteredText.append(replacementString)
                for char in formatPattern {
                    if filteredText.count <= offset {
                        break
                    }
                    if char != "#" {
                        formattedText.append(char)
                    } else {
                        let currentChar = filteredText[filteredText.index(text.startIndex, offsetBy: offset)]
                        formattedText.append(currentChar)
                        offset += 1
                    }
                }
            }
        }
        if formattedText.count > 0 {
            formattedText.removeLast()
        }
        return formattedText
    }
}

extension FormatTextField {
    override var description: String {
        return NSStringFromClass(self.classForCoder)
    }
}

extension FormatTextField {
      /// event for textField
    override public func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {}

      ///  Replace native textfield delgate with custom one.
//    override public var delegate: UITextFieldDelegate? {
//        get { return self }
//        set {}
//    }

    func addSomeTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        super.addTarget(target, action: action, for: controlEvents)
    }
}
