import Foundation

#if os(iOS)
import UIKit
#endif


public class TextField: SkyflowElement, Element {
    internal var textField = FormatTextField(frame: .zero)
    internal var errorMessage = PaddingLabel(frame: .zero)
    internal var isDirty = false
    internal var validationRules = ValidationSet()
    internal var userValidationRules = ValidationSet()
    internal var stackView = UIStackView()
    internal var textFieldLabel = PaddingLabel(frame: .zero)
    internal var hasBecomeResponder: Bool = false
    
    internal var isErrorMessageShowing: Bool {
        return self.errorMessage.alpha == 1.0
    }

    internal var textFieldCornerRadius: CGFloat {
        get {
            return textField.layer.cornerRadius
        }
        set {
            textField.layer.cornerRadius = newValue
            textField.layer.masksToBounds = newValue > 0
        }
    }

    internal var textFieldBorderWidth: CGFloat {
        get {
            return textField.layer.borderWidth
        }
        set {
            textField.layer.borderWidth = newValue
        }
    }

    internal var textFieldBorderColor: UIColor? {
        get {
            guard let cgcolor = textField.layer.borderColor else {
                return nil
            }
            return UIColor(cgColor: cgcolor)
        }
        set {
            textField.layer.borderColor = newValue?.cgColor
        }
    }

    internal var textFieldPadding = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0) {
        didSet { setMainPaddings() }
    }

    /// Describes `SkyflowTextField` input   State`
    internal override var state: State {
        return StateforText(tf: self)
    }

    override init(input: CollectElementInput, options: CollectElementOptions, contextOptions: ContextOptions) {
        super.init(input: input, options: options, contextOptions: contextOptions)
        //        self.contextOptions = contextOptions
        self.userValidationRules.append(input.validations)
        setupField()
    }

    required internal init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }


    internal func isMounted() -> Bool {
        var flag = false
        if Thread.isMainThread {
            flag = self.window != nil
        } else {
            DispatchQueue.main.sync {
                flag = self.window != nil
            }
        }
        return flag
    }
    

    internal var hasFocus = false

    internal var onChangeHandler: (([String: Any]) -> Void)?
    internal var onBlurHandler: (([String: Any]) -> Void)?
    internal var onReadyHandler: (([String: Any]) -> Void)?
    internal var onFocusHandler: (([String: Any]) -> Void)?

    override func getOutput() -> String? {
        return textField.getTextwithFormatPattern
    }

    internal var actualValue: String = ""

    internal func getValue() -> String {
        return actualValue
    }

    internal func getOutputTextwithoutFormatPattern() -> String? {
        return textField.getSecureRawText
    }

    /// Field Configuration
    override func setupField() {
        super.setupField()
        textField.placeholder = collectInput.placeholder
        updateInputStyle()
        // textField.formatPattern = fieldType.instance.formatPattern
        if let instance = fieldType.instance {
            validationRules = instance.validation
            textField.keyboardType = instance.keyboardType
        }


        // Base label styles
        self.textFieldLabel.textColor = collectInput.labelStyles.base?.textColor ?? .none
        self.textFieldLabel.font = collectInput.labelStyles.base?.font ?? .none
        self.textFieldLabel.textAlignment = collectInput.labelStyles.base?.textAlignment ?? .left
        self.textFieldLabel.insets = collectInput.labelStyles.base?.padding ?? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        // Base errorText styles
        self.errorMessage.textColor = collectInput.errorTextStyles.base?.textColor ?? .none
        self.errorMessage.font = collectInput.errorTextStyles.base?.font ?? .none
        self.errorMessage.textAlignment = collectInput.errorTextStyles.base?.textAlignment ?? .left
        self.errorMessage.insets = collectInput.errorTextStyles.base?.padding ?? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        if self.fieldType == .CARD_NUMBER, self.options.enableCardIcon {
            textField.leftViewMode = UITextField.ViewMode.always
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            #if SWIFT_PACKAGE
            let image = UIImage(named: "Unknown-Card", in: Bundle.module, compatibleWith: nil)
            #else
            let frameworkBundle = Bundle(for: TextField.self)
            var bundleURL = frameworkBundle.resourceURL
            bundleURL!.appendPathComponent("Skyflow.bundle")
            let resourceBundle = Bundle(url: bundleURL!)
            let image = UIImage(named: "Unknown-Card", in: resourceBundle, compatibleWith: nil)
            #endif
            imageView.image = image
            imageView.contentMode = .center
            let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 20 , height: 20))
            containerView.addSubview(imageView)
            textField.leftView = containerView
        }

        if let altText = self.collectInput.altText {
            self.textField.secureText = altText
        }
        
        if self.fieldType == .CARD_NUMBER {
            let t = getOutput()!.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
            let card = CardType.forCardNumber(cardNumber: t)
            updateImage(name: card.imageName)
        }
        
    }

    internal func updateImage(name: String){
        
        if self.options.enableCardIcon == false {
            return
        }

        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20 + (0), height: 20))
        #if SWIFT_PACKAGE
        let image = UIImage(named: name, in: Bundle.module, compatibleWith: nil)
        #else
        let frameworkBundle = Bundle(for: TextField.self)
        var bundleURL = frameworkBundle.resourceURL
        bundleURL!.appendPathComponent("Skyflow.bundle")
        let resourceBundle = Bundle(url: bundleURL!)
        let image = UIImage(named: name, in: resourceBundle, compatibleWith: nil)
        #endif
        imageView.image = image
        imageView.contentMode = .center
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 20))
        containerView.addSubview(imageView)
        textField.leftView = containerView
    }
    
    override func validate() -> SkyflowValidationError {
        let str = textField.getSecureRawText ?? ""
        return SkyflowValidator.validate(input: str, rules: validationRules)
    }

    internal func isValid() -> Bool {
        let state = self.state.getState()
        if (state["isRequired"] as! Bool) && (state["isEmpty"] as! Bool || self.actualValue.isEmpty) {
            return false
        }
        if !(state["isValid"] as! Bool) {
            return false
        }
        return true
    }

    public func on(eventName: EventName, handler: @escaping ([String: Any]) -> Void) {
        switch eventName {
        case .CHANGE:
            onChangeHandler = handler
        case .BLUR:
            onBlurHandler = handler
        case .READY:
            onReadyHandler = handler
        case .FOCUS:
            onFocusHandler = handler
        }
    }

    public override func didMoveToWindow() {
        if self.window != nil {
            onReadyHandler?((self.state as! StateforText).getStateForListener())
        }
    }
    
    public func unmount() {
        self.actualValue = ""
        self.textField.secureText = ""
        self.setupField()
    }
}
/// UIResponder methods
extension TextField {
    /// Make `SkyflowTextField` focused.
    @discardableResult override public func becomeFirstResponder() -> Bool {
        self.hasBecomeResponder = true
        return textField.becomeFirstResponder()
    }

    /// Remove  focus from `SkyflowTextField`.
    @discardableResult override public func resignFirstResponder() -> Bool {
        self.hasBecomeResponder = false
        return textField.resignFirstResponder()
    }

    /// Check if `SkyflowTextField` is focused.
    override public var isFirstResponder: Bool {
        return textField.isFirstResponder
    }
    
}

/// Textfield delegate
extension TextField: UITextFieldDelegate {
    private func updateInputStyle(_ style: Style? = nil) {
        let fallbackStyle = self.collectInput.inputStyles.base
        self.textField.font = style?.font ?? fallbackStyle?.font ?? .none
        self.textField.textAlignment = style?.textAlignment ?? fallbackStyle?.textAlignment ?? .natural
        self.textField.textColor = style?.textColor ?? fallbackStyle?.textColor ?? .none
        var p = style?.padding ?? fallbackStyle?.padding ?? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        if self.fieldType == .CARD_NUMBER, self.options.enableCardIcon {
            p.left += 45
        }
        self.textField.padding = p
        self.textFieldBorderWidth = style?.borderWidth ?? fallbackStyle?.borderWidth ?? 0
        self.textFieldBorderColor = style?.borderColor ?? fallbackStyle?.borderColor ?? .none
        self.textFieldCornerRadius = style?.cornerRadius ?? fallbackStyle?.cornerRadius ?? 0
    }

    private func updateLabelStyle(_ style: Style? = nil) {
        let fallbackStyle = self.collectInput!.labelStyles.base
        self.textFieldLabel.textColor = style?.textColor ?? fallbackStyle?.textColor ?? .none
        self.textFieldLabel.font = style?.font ?? fallbackStyle?.font ?? .none
        self.textFieldLabel.textAlignment = style?.textAlignment ?? fallbackStyle?.textAlignment ?? .left
        self.textFieldLabel.insets = style?.padding ?? fallbackStyle?.padding ?? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }


    /// Wrap native `UITextField` delegate method for `textFieldDidBeginEditing`.
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        self.hasFocus = true
        textFieldValueChanged()
        // element styles on focus
        updateInputStyle(collectInput.inputStyles.focus)

        // label styles on focus
        updateLabelStyle(collectInput!.labelStyles.focus)
        onFocusHandler?((self.state as! StateforText).getStateForListener())
    }

    /// Wrap native `UITextField` delegate method for `didChange`.
    @objc func textFieldDidChange(_ textField: UITextField) {
        isDirty = true
        updateActualValue()
        textFieldValueChanged()
        onChangeHandler?((self.state as! StateforText).getStateForListener())
        
        if self.fieldType == .CARD_NUMBER {
            let t = getOutput()!.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
            let card = CardType.forCardNumber(cardNumber: t)
            updateImage(name: card.imageName)
        }
    }

    func updateActualValue() {
        self.actualValue = textField.secureText ?? ""
    }

    /// Wrap native `UITextField` delegate method for `didEndEditing`.
    public func textFieldDidEndEditing(_ textField: UITextField) {
        self.hasFocus = false
        textFieldValueChanged()
        let state = self.state.getState()

        // Set label styles to base
        updateLabelStyle()

        if state["isEmpty"] as! Bool {
            updateInputStyle(collectInput!.inputStyles.empty)
            errorMessage.alpha = 0.0 // Hide error message
        } else if !(state["isValid"] as! Bool) {
            updateInputStyle(collectInput!.inputStyles.invalid)
            errorMessage.alpha = 1.0 // Show error message

        } else {
            updateInputStyle(collectInput!.inputStyles.complete)
            errorMessage.alpha = 0.0 // Hide error message
        }
        onBlurHandler?((self.state as! StateforText).getStateForListener())
    }

    @objc func textFieldDidEndEditingOnExit(_ textField: UITextField) {
        textFieldValueChanged()
    }
}

internal extension TextField {
//
//    func leftImage(_ image: UIImage?, imageWidth: CGFloat, padding: CGFloat) {
//        let imageView = UIImageView(image: image)
//        imageView.frame = CGRect(x: padding, y: 0, width: imageWidth, height: frame.height)
//        imageView.contentMode = .center
//
//        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: imageWidth + 2 * padding, height: frame.height))
//        containerView.addSubview(imageView)
//        leftView = containerView
//        leftViewMode = .always
//    }
    
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
        errorMessage.translatesAutoresizingMaskIntoConstraints = false

        errorMessage.alpha = 0.0
        errorMessage.text = "Invalid " + (self.collectInput.label != "" ? self.collectInput.label : "element")

        textFieldLabel.text = collectInput.label

        stackView.addArrangedSubview(textFieldLabel)
        stackView.addArrangedSubview(textField)
        stackView.addArrangedSubview(errorMessage)

        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

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

        let views = ["view": self, "stackView": stackView]

        horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(0)-[stackView]-\(0)-|",
                                                               options: .alignAllCenterY,
                                                               metrics: nil,
                                                               views: views)
        NSLayoutConstraint.activate(horizontalConstraints)

        verticalConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-\(0)-[stackView]-\(0)-|",
                                                            options: .alignAllCenterX,
                                                            metrics: nil,
                                                            views: views)
        NSLayoutConstraint.activate(verticalConstraint)
    }

    @objc
    func textFieldValueChanged() {
        /// update format pattern after field input changed
        //        if self.fieldType == .cardNumber {
        //            let card = CardType.forCardNumber(cardNumber: getOutput()!)
        //            if card.defaultName != "Empty"  {
        //                self.textField.formatPattern = card.formatPattern
        //              } else {
        //                self.textField.formatPattern = CardType.UNKNOWN.instance.formatPattern
        //              }
        //        }
        //        textField.updateTextFormat()
    }

    /// change focus here
    @objc
    func focusOn() {
        // change status
        textField.becomeFirstResponder()
        textFieldValueChanged()
    }
}
