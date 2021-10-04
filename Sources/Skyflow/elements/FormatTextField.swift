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
        self.formatText()
    }

    fileprivate func getOnlyDigitsString(_ string: String) -> String {
        let charactersArray = string.components(separatedBy: CharacterSet.SkyflowAsciiDecimalDigits.inverted)
        return charactersArray.joined(separator: "")
    }

    fileprivate func getOnlyLettersString(_ string: String) -> String {
        let charactersArray = string.components(separatedBy: CharacterSet.letters.inverted)
        return charactersArray.joined(separator: "")
    }

    fileprivate func getUppercaseLettersString(_ string: String) -> String {
        let charactersArray = string.components(separatedBy: CharacterSet.uppercaseLetters.inverted)
        return charactersArray.joined(separator: "")
    }

    fileprivate func getLowercaseLettersString(_ string: String) -> String {
        let charactersArray = string.components(separatedBy: CharacterSet.lowercaseLetters.inverted)
        return charactersArray.joined(separator: "")
    }

    fileprivate func getFilteredString(_ string: String) -> String {
        let charactersArray = string.components(separatedBy: CharacterSet.alphanumerics.inverted)
        return charactersArray.joined(separator: "")
    }

    fileprivate func getRawText() -> String? {
        guard let text = secureText else {
            return nil
        }
        return formatPattern.isEmpty ? secureText : getFilteredString(text)
    }


    fileprivate func getText(_ string: String) -> String {
            return string
    }

    /**
     Func that formats the text based on formatPattern
     */
    func formatText() {
        var textForFormatting = ""

        if let text = super.text {
            if text.count > 0 {
                textForFormatting = self.getText(text)
            }
        }

        if self.maxLength > 0 {
            var formatterIndex = self.formatPattern.startIndex, textForFormattingIndex = textForFormatting.startIndex
            textwithFormatPattern = ""

            textForFormatting = self.getFilteredString(textForFormatting)

            if textForFormatting.count > 0 {
                while true {
                    let patternRange = formatterIndex ..< formatPattern.index(after: formatterIndex)
                    let currentFormatCharacter = String(self.formatPattern[patternRange])
                    if let currentFormatCharacterType = FormatPatternChar(rawValue: currentFormatCharacter) {
                        let textForFormattingPatterRange = textForFormattingIndex ..< textForFormatting.index(after: textForFormattingIndex)
                        let textForFormattingCharacter = String(textForFormatting[textForFormattingPatterRange])

                        switch currentFormatCharacterType {
                        case .lettersAndDigit:
                            textwithFormatPattern += textForFormattingCharacter
                            textForFormattingIndex = textForFormatting.index(after: textForFormattingIndex)
                            formatterIndex = formatPattern.index(after: formatterIndex)
                        case .anyLetter:
                            let filteredChar = self.getOnlyLettersString(textForFormattingCharacter)
                            if !filteredChar.isEmpty {
                                textwithFormatPattern += filteredChar
                                formatterIndex = formatPattern.index(after: formatterIndex)
                            }
                            textForFormattingIndex = textForFormatting.index(after: textForFormattingIndex)
                        case .lowerCaseLetter:
                            let filteredChar = self.getLowercaseLettersString(textForFormattingCharacter)
                            if !filteredChar.isEmpty {
                                textwithFormatPattern += filteredChar
                                formatterIndex = formatPattern.index(after: formatterIndex)
                            }
                            textForFormattingIndex = textForFormatting.index(after: textForFormattingIndex)
                        case .upperCaseLetter:
                            let filteredChar = self.getUppercaseLettersString(textForFormattingCharacter)
                            if !filteredChar.isEmpty {
                                textwithFormatPattern += filteredChar
                                formatterIndex = formatPattern.index(after: formatterIndex)
                            }
                            textForFormattingIndex = textForFormatting.index(after: textForFormattingIndex)
                        case .digits:
                            let filteredChar = self.getOnlyDigitsString(textForFormattingCharacter)
                            if !filteredChar.isEmpty {
                                textwithFormatPattern += filteredChar
                                formatterIndex = formatPattern.index(after: formatterIndex)
                            }
                            textForFormattingIndex = textForFormatting.index(after: textForFormattingIndex)
                        }
                    } else {
                        textwithFormatPattern += currentFormatCharacter
                        formatterIndex = formatPattern.index(after: formatterIndex)
                    }

                    if formatterIndex >= self.formatPattern.endIndex ||
                        textForFormattingIndex >= textForFormatting.endIndex {
                        break
                    }
                }
            }


            super.text = textwithFormatPattern
            if let text = self.secureText {
                if text.count > self.maxLength {
                    super.text = String(text[text.index(text.startIndex, offsetBy: self.maxLength - 1)])
                }
            }
        }
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
    override public var delegate: UITextFieldDelegate? {
        get { return nil }
        set {}
    }

    func addSomeTarget(_ target: Any?, action: Selector, for controlEvents: UIControl.Event) {
        super.addTarget(target, action: action, for: controlEvents)
    }
}
