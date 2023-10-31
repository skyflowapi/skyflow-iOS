/*
 * Copyright (c) 2022 Skyflow
 */

/*
 *Implementation of SkyflowInputField which
 *is a combination of [Label, TextField, ValidationErrorMessage]
 */

import Foundation

#if os(iOS)
import UIKit
#endif


public class TextField: SkyflowElement, Element, BaseElement {
    var onBeginEditing: (() -> Void)?
    var onEndEditing: (() -> Void)?
    var onFocusIsTrue: (() -> Void)?
    internal var textField = FormatTextField(frame: .zero)
    internal var errorMessage = PaddingLabel(frame: .zero)
    internal var isDirty = false
    internal var validationRules = ValidationSet()
    internal var userValidationRules = ValidationSet()
    internal var stackView = UIStackView()
    internal var textFieldLabel = PaddingLabel(frame: .zero)
    internal var hasBecomeResponder: Bool = false
    internal var copyIconImageView: UIImageView?
    
    internal var textFieldDelegate: UITextFieldDelegate? = nil
    
    internal var errorTriggered: Bool = false
    
    internal var isErrorMessageShowing: Bool {
        return self.errorMessage.alpha == 1.0
    }
    
    internal var uuid: String = ""
    
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
    
    internal override var state: State {
        return StateforText(tf: self)
    }
    
    override init(input: CollectElementInput, options: CollectElementOptions, contextOptions: ContextOptions, elements: [TextField]? = nil) {
        super.init(input: input, options: options, contextOptions: contextOptions, elements: elements ?? [])
        self.userValidationRules.append(input.validations)
        self.textFieldDelegate = TextFieldValidationDelegate(collectField: self)
        self.textField.delegate = self.textFieldDelegate!
        setFormatPattern()
        setupField()
        let formatNotSupportedElements = [ElementType.CARDHOLDER_NAME, ElementType.EXPIRATION_MONTH, ElementType.CVV, ElementType.PIN]
        if(formatNotSupportedElements.contains(fieldType)) {
            var context = self.contextOptions
            context?.interface = .COLLECT_CONTAINER
            context?.logLevel = .WARN
            if(options.translation != nil || options.format != "mm/yy"){
                Log.warn(message: .FORMAT_AND_TRANSLATION, values: [fieldType.name], contextOptions: context!)
            }
        }
    }
    
    internal func addValidations() {
        if self.fieldType == .EXPIRATION_DATE {
            self.addDateValidations()
        } else if self.fieldType == .EXPIRATION_YEAR {
            self.addYearValidations()
        } else if self.fieldType == .EXPIRATION_MONTH {
            self.addMonthValidations()
        }
    }
    
    internal func addDateValidations() {
        let defaultFormat = "mm/yy"
        let supportedFormats = [defaultFormat, "mm/yyyy", "yy/mm", "yyyy/mm"]
        if !supportedFormats.contains(self.options.format.lowercased()) {
            var context = self.contextOptions
            context?.interface = .COLLECT_CONTAINER
            Log.warn(message: .INVALID_EXPIRYDATE_FORMAT, values: [self.options.format.lowercased()], contextOptions: context!)
            self.options.format = defaultFormat
        }
        let expiryDateRule = SkyflowValidateCardExpirationDate(format: options.format, error: SkyflowValidationErrorType.expirationDate.rawValue)
        self.validationRules.append(ValidationSet(rules: [expiryDateRule]))
    }
    
    internal func addMonthValidations() {
        let monthRule = SkyflowValidateExpirationMonth(error: SkyflowValidationErrorType.expirationMonth.rawValue)
        self.validationRules.append(ValidationSet(rules: [monthRule]))
    }
    
    internal func addYearValidations() {
        var format = "yyyy"
        if self.options.format.lowercased() == "yy" {
            format = "yy"
        }
        
        let yearRule = SkyflowValidateExpirationYear(format: format, error: SkyflowValidationErrorType.expirationYear.rawValue)
        self.validationRules.append(ValidationSet(rules: [yearRule]))
    }
    
    internal func setFormatPattern() {
        switch fieldType {
        case .CARD_NUMBER:
            let cardType = CardType.forCardNumber(cardNumber: self.actualValue).instance
            if(options.format.uppercased() == "XXXX-XXXX-XXXX-XXXX"){
              self.textField.formatPattern = cardType.formatPattern.replacingOccurrences(of: " ", with: "-")
            } else {
                self.textField.formatPattern = cardType.formatPattern

            }
        case .EXPIRATION_DATE:
            self.textField.formatPattern = self.options.format.lowercased().replacingOccurrences(of: "\\w", with: "#", options: .regularExpression)
        default:
            if let instance = fieldType.instance {
                self.textField.formatPattern = instance.formatPattern
            }
        }
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
    internal var onSubmitHandler: (() -> Void)?

    
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
    
    public func update(update: CollectElementInput){
        collectInput.placeholder = update.placeholder
        if update.column.isEmpty != true {
            collectInput.column = update.column
        }
        if update.table.isEmpty != true {
            collectInput.table = update.table
        }
        if update.column.isEmpty != true {
            collectInput.column = update.column
        }
        if update.label.isEmpty != true {
            collectInput.label = update.label
        }
        if update.validations.rules.isEmpty != true {
            collectInput.validations = update.validations
        }
         updateStyle(update.inputStyles.base, &collectInput.inputStyles.base)
         updateStyle(update.inputStyles.complete, &collectInput.inputStyles.complete)
         updateStyle(update.inputStyles.empty, &collectInput.inputStyles.empty)
         updateStyle(update.inputStyles.focus, &collectInput.inputStyles.focus)
         updateStyle(update.inputStyles.invalid, &collectInput.inputStyles.invalid)
         updateStyle(update.inputStyles.requiredAstrisk, &collectInput.inputStyles.invalid)

         updateStyle(update.labelStyles.base, &collectInput.labelStyles.base)
         updateStyle(update.labelStyles.complete, &collectInput.labelStyles.complete)
         updateStyle(update.labelStyles.empty, &collectInput.labelStyles.empty)
         updateStyle(update.labelStyles.focus, &collectInput.labelStyles.focus)
         updateStyle(update.labelStyles.invalid, &collectInput.labelStyles.invalid)
         updateStyle(update.labelStyles.requiredAstrisk, &collectInput.labelStyles.requiredAstrisk)
        
         updateStyle(update.errorTextStyles.base, &collectInput.errorTextStyles.base)
         updateStyle(update.errorTextStyles.complete, &collectInput.errorTextStyles.complete)
         updateStyle(update.errorTextStyles.empty, &collectInput.errorTextStyles.empty)
         updateStyle(update.errorTextStyles.focus, &collectInput.errorTextStyles.focus)
         updateStyle(update.errorTextStyles.invalid, &collectInput.errorTextStyles.invalid)
         updateStyle(update.errorTextStyles.requiredAstrisk, &collectInput.errorTextStyles.requiredAstrisk)
        
         updateStyle(update.iconStyles.base, &collectInput.iconStyles.base)
         updateStyle(update.iconStyles.complete, &collectInput.iconStyles.complete)
         updateStyle(update.iconStyles.empty, &collectInput.iconStyles.empty)
         updateStyle(update.iconStyles.focus, &collectInput.iconStyles.focus)
         updateStyle(update.iconStyles.invalid, &collectInput.iconStyles.invalid)
         updateStyle(update.iconStyles.requiredAstrisk, &collectInput.iconStyles.requiredAstrisk)

        setupField()
    }
    func updateStyle(_ source: Style?, _ destination: inout Style?) {
            guard let newStyle = source else { return }
            if destination == nil {
                destination = Style()
            }
        if (newStyle.borderColor != nil) {
            destination?.borderColor = newStyle.borderColor
        }
        if (newStyle.cornerRadius != nil){
            destination?.cornerRadius = newStyle.cornerRadius
        }
        if (newStyle.padding != nil){
            destination?.padding = newStyle.padding

        }
        if (newStyle.textAlignment != nil){
            destination?.textAlignment = newStyle.textAlignment

        }
        if (newStyle.borderWidth != nil){
            destination?.borderWidth = newStyle.borderWidth

        }
        if (newStyle.font != nil){
            destination?.font = newStyle.font

        }
        if (newStyle.width != nil){
            destination?.width = newStyle.width

        }
        if (newStyle.height != nil){
            destination?.height = newStyle.height

        }
        }
    
    public func setValue(value: String) {
        if(contextOptions.env == .DEV){
            if(self.fieldType == .INPUT_FIELD && !(options.format == "mm/yy" || options.format == "")){
                if(options.translation == nil){
                    options.translation = ["X": "[0-9]"]
                }
                for (key, value) in options.translation! {
                    if value == "" {
                        options.translation![key] = "(?:)"
                    }
                }
                let result =  self.textField.formatInput(input: value, format: options.format, translation: options.translation!)
                self.textField.secureText = result
                actualValue = result
            }else {
                actualValue = value
                
                self.textField.addAndFormatText(value)
            }
            textFieldDidChange(self.textField)

        } else {
            var context = self.contextOptions
            context?.interface = .COLLECT_CONTAINER
            Log.warn(message: .SET_VALUE_WARNING, values: [self.collectInput.type?.name ?? "collect"],contextOptions: context!)
        }
    }
    
    public func clearValue(){
        if(contextOptions.env == .DEV){
            actualValue = ""
            textField.secureText = ""
        } else {
            var context = self.contextOptions
            context?.interface = .COLLECT_CONTAINER
            Log.warn(message: .CLEAR_VALUE_WARNING, values: [self.collectInput.type?.name ?? "collect"],contextOptions: context!)
        }
    }
    
    override func setupField() {
        super.setupField()
        textField.placeholder = collectInput.placeholder
        updateInputStyle()
        if let instance = fieldType.instance {
            validationRules = instance.validation
            textField.keyboardType = instance.keyboardType
        }
        addValidations()
        if collectInput.inputStyles.base?.width != nil {
            NSLayoutConstraint.activate([
                self.textField.widthAnchor.constraint(equalToConstant: (collectInput.inputStyles.base?.width)!)
            ])

        }
        if collectInput.inputStyles.base?.height != nil {
            NSLayoutConstraint.activate([
                self.textField.heightAnchor.constraint(equalToConstant: (collectInput.inputStyles.base?.height)!)
            ])

        }
        
        self.textFieldLabel.textColor = collectInput.labelStyles.base?.textColor ?? .none
        self.textFieldLabel.font = collectInput.labelStyles.base?.font ?? .none
        self.textFieldLabel.textAlignment = collectInput.labelStyles.base?.textAlignment ?? .left
        self.textFieldLabel.insets = collectInput.labelStyles.base?.padding ?? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.errorMessage.textColor = collectInput.errorTextStyles.base?.textColor ?? .none
        self.errorMessage.font = collectInput.errorTextStyles.base?.font ?? .none
        self.errorMessage.textAlignment = collectInput.errorTextStyles.base?.textAlignment ?? .left
        self.errorMessage.insets = collectInput.errorTextStyles.base?.padding ?? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        if self.fieldType == .CARD_NUMBER, self.options.enableCardIcon {
            textField.leftViewMode = UITextField.ViewMode.always
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
            #if SWIFT_PACKAGE
            var image = UIImage(named: "Unknown-Card", in: Bundle.module, compatibleWith: nil)
            #else
            let frameworkBundle = Bundle(for: TextField.self)
            var bundleURL = frameworkBundle.resourceURL
            bundleURL!.appendPathComponent("Skyflow.bundle")
            let resourceBundle = Bundle(url: bundleURL!)
            var image = UIImage(named: "Unknown-Card", in: resourceBundle, compatibleWith: nil)
            #endif
            imageView.image = image
            imageView.contentMode = .center
            let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 20 , height: 24))
            containerView.addSubview(imageView)
            textField.leftView = containerView
        }
        if self.options.enableCopy {
            textField.rightViewMode =  UITextField.ViewMode.always
            textField.rightView = addCopyIcon()
            textField.rightView?.isHidden = true
        }

        
        if self.fieldType == .CARD_NUMBER {
            let t = self.textField.secureText!.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
            let card = CardType.forCardNumber(cardNumber: t).instance
            updateImage(name: card.imageName)
        }
        
        setFormatPattern()
        
    }
    
    private func addCopyIcon() -> UIView{
        copyIconImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        #if SWIFT_PACKAGE
        let image = UIImage(named: "Copy-Icon", in: Bundle.module, compatibleWith: nil)
        #else
        let frameworkBundle = Bundle(for: TextField.self)
        var bundleURL = frameworkBundle.resourceURL
        bundleURL!.appendPathComponent("Skyflow.bundle")
        let resourceBundle = Bundle(url: bundleURL!)
        var image = UIImage(named: "Copy-Icon", in: resourceBundle, compatibleWith: nil)
        #endif
        copyIconImageView?.image = image
        copyIconImageView?.contentMode = .scaleAspectFit
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 24 , height: 24))
        containerView.addSubview(copyIconImageView!)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(copyIconTapped(_:)))
        containerView.isUserInteractionEnabled = true
        containerView.addGestureRecognizer(tapGesture)
        return containerView
    }
    @objc private func copyIconTapped(_ sender: UITapGestureRecognizer) {
        // Copy text when the copy icon is tapped
        copy(sender)
    }
    @objc
    public override func copy(_ sender: Any?) {
        let pasteboard = UIPasteboard.general
        pasteboard.string = actualValue
        #if SWIFT_PACKAGE
        let image = UIImage(named: "Success-Icon", in: Bundle.module, compatibleWith: nil)
        #else
        let frameworkBundle = Bundle(for: TextField.self)
        var bundleURL = frameworkBundle.resourceURL
        bundleURL!.appendPathComponent("Skyflow.bundle")
        let resourceBundle = Bundle(url: bundleURL!)
        var image = UIImage(named: "Success-Icon", in: resourceBundle, compatibleWith: nil)
        #endif
        copyIconImageView?.image = image

        // Reset the copy icon after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            #if SWIFT_PACKAGE
            let copyImage = UIImage(named: "Copy-Icon", in: Bundle.module, compatibleWith: nil)
            #else
            let frameworkBundle = Bundle(for: TextField.self)
            var bundleURL = frameworkBundle.resourceURL
            bundleURL!.appendPathComponent("Skyflow.bundle")
            let resourceBundle = Bundle(url: bundleURL!)
            var copyImage = UIImage(named: "Copy-Icon", in: resourceBundle, compatibleWith: nil)
            #endif
            self?.copyIconImageView?.image = copyImage
        }
            
    }
    internal func updateImage(name: String){
        
        if self.options.enableCardIcon == false {
            return
        }
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40 + (0), height: 24))
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
        imageView.layer.cornerRadius = self.collectInput!.iconStyles.base?.cornerRadius ?? 0
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 40))
        containerView.addSubview(imageView)
        imageView.center = containerView.center
        imageView.bounds = imageView.frame.inset(by: self.collectInput!.iconStyles.base?.padding ?? UIEdgeInsets(top: .zero, left: .zero, bottom: .zero, right: .zero))
        imageView.layer.borderColor = self.collectInput!.iconStyles.base?.borderColor?.cgColor
        imageView.layer.borderWidth = self.collectInput!.iconStyles.base?.borderWidth ?? 0
        imageView.layer.cornerRadius = self.collectInput!.iconStyles.base?.cornerRadius ?? 0
        textField.leftViewMode = .always
        textField.leftView = containerView
    }
    
    override func validate() -> SkyflowValidationError {
        let str = actualValue
        if self.errorTriggered {
            return self.errorMessage.text!
        }
        return SkyflowValidator.validate(input: str, rules: validationRules)
    }
    
    func validateCustomRules() -> SkyflowValidationError {
        let str = actualValue
        if self.errorTriggered {
            return ""
        }
        return SkyflowValidator.validate(input: str, rules: userValidationRules)
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
        case .SUBMIT:
            break
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
extension TextField {
    @discardableResult override public func becomeFirstResponder() -> Bool {
        self.hasBecomeResponder = true
        return textField.becomeFirstResponder()
    }
    
    @discardableResult override public func resignFirstResponder() -> Bool {
        self.hasBecomeResponder = false
        return textField.resignFirstResponder()
    }
    override public var isFirstResponder: Bool {
        return textField.isFirstResponder
    }
    
}

extension TextField {
    
    internal func updateInputStyle(_ style: Style? = nil) {
        let fallbackStyle = self.collectInput.inputStyles.base
        self.textField.font = style?.font ?? fallbackStyle?.font ?? .none
        self.textField.textAlignment = style?.textAlignment ?? fallbackStyle?.textAlignment ?? .natural
        self.textField.textColor = style?.textColor ?? fallbackStyle?.textColor ?? .none
        self.textField.tintColor = style?.cursorColor ?? fallbackStyle?.cursorColor ?? UIColor.black
        var p = style?.padding ?? fallbackStyle?.padding ?? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        if self.fieldType == .CARD_NUMBER, self.options.enableCardIcon {
            p.left = 60
        }
        if style?.width != nil {
            NSLayoutConstraint.activate ([
                self.textField.widthAnchor.constraint(equalToConstant: (style?.width)!)
            ])
            
        }
        if style?.height != nil {
        self.textField.heightAnchor.constraint(equalToConstant: (style?.height)!).isActive = true
        }
        self.textField.padding = p
        self.textFieldBorderWidth = style?.borderWidth ?? fallbackStyle?.borderWidth ?? 0
        self.textFieldBorderColor = style?.borderColor ?? fallbackStyle?.borderColor ?? .none
        self.textFieldCornerRadius = style?.cornerRadius ?? fallbackStyle?.cornerRadius ?? 0
    }
    
    internal func updateLabelStyle(_ style: Style? = nil) {
        let fallbackStyle = self.collectInput!.labelStyles.base
        self.textFieldLabel.textColor = style?.textColor ?? fallbackStyle?.textColor ?? .none
        self.textFieldLabel.font = style?.font ?? fallbackStyle?.font ?? .none
        self.textFieldLabel.textAlignment = style?.textAlignment ?? fallbackStyle?.textAlignment ?? .left
        self.textFieldLabel.insets = style?.padding ?? fallbackStyle?.padding ?? UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    internal func textFieldDidEndEditing(_ textField: UITextField) {
        self.textField.delegate?.textFieldDidEndEditing?(textField)
    }
    
    
    @objc func  textFieldDidChange(_ textField: UITextField) {
        isDirty = true
        updateActualValue()
        textFieldValueChanged()
        onChangeHandler?((self.state as! StateforText).getStateForListener())
        if self.fieldType == .CARD_NUMBER {
            let t = self.textField.secureText!.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
            let card = CardType.forCardNumber(cardNumber: t).instance
            updateImage(name: card.imageName)
        }
        setFormatPattern()
        onBeginEditing?()

        if self.options.enableCopy && (self.state.getState()["isValid"] as! Bool && !self.actualValue.isEmpty) {
            self.textField.rightViewMode = .always
            self.textField.rightView?.isHidden = false
        } else if self.options.enableCopy {
            self.textField.rightViewMode = .always
            self.textField.rightView?.isHidden = true
        }

    }
    
    func updateActualValue() {
        if self.fieldType == .CARD_NUMBER {
            self.actualValue = textField.getSecureRawText ?? ""
        } else {
            self.actualValue = textField.secureText ?? ""
        }
    }
    
    func updateErrorMessage() {
        
        var isRequiredCheckFailed = false
        
        let currentState = state.getState()
        if self.errorTriggered == false {
            if self.hasFocus {
                updateInputStyle(collectInput!.inputStyles.focus)
                errorMessage.alpha = 0.0
            }
            else if (currentState["isEmpty"] as! Bool || self.actualValue.isEmpty) {
                if currentState["isRequired"] as! Bool{
                    isRequiredCheckFailed = true
                    updateInputStyle(collectInput!.inputStyles.empty)
                    errorMessage.alpha = 1.0
                }else {
                    updateInputStyle(collectInput!.inputStyles.complete)
                    errorMessage.alpha = 0.0
                }
            } else if !(currentState["isValid"] as! Bool) {
                updateInputStyle(collectInput!.inputStyles.invalid)
                errorMessage.alpha = 1.0
            } else {
                updateInputStyle(collectInput!.inputStyles.complete)
                errorMessage.alpha = 0.0
            }
            let label = self.collectInput.label
            
            // Error message
            if isRequiredCheckFailed {
                errorMessage.text =  "Value is required"
            }
            else if  currentState["isDefaultRuleFailed"] as! Bool{
                errorMessage.text = "Invalid " + (label != "" ? label : "element")
            }
            else if currentState["isCustomRuleFailed"] as! Bool{
                if SkyflowValidationErrorType(rawValue: currentState["validationError"] as! String) != nil {
                    errorMessage.text = "Validation failed"
                }
                else {
                    errorMessage.text = currentState["validationError"] as? String
                }

            }
        } else {
            updateInputStyle(collectInput!.inputStyles.invalid)
            errorMessage.alpha = 1.0
        }
        onEndEditing?()
    }
}

internal extension TextField {
    
    @objc
    override func initialization() {
        super.initialization()
        buildTextFieldUI()
        addTextFieldObservers()
    }
    
    
    @objc
    func buildTextFieldUI() {
        textField.translatesAutoresizingMaskIntoConstraints = false
        errorMessage.translatesAutoresizingMaskIntoConstraints = false
        textFieldLabel.translatesAutoresizingMaskIntoConstraints = false
        
        errorMessage.alpha = 0.0
        errorMessage.text = "Invalid " + (self.collectInput.label != "" ? self.collectInput.label : "element")
        let text = collectInput.label
        
        var verticalAstrisk = -(collectInput.labelStyles.requiredAstrisk?.padding?.top ?? 0.0 ) + (collectInput.labelStyles.requiredAstrisk?.padding?.bottom ?? 0.0 )
        
        let astriskAttributes: [NSAttributedString.Key: Any]  = [
            .strokeWidth:  -3.0,
            .strokeColor: collectInput.labelStyles.requiredAstrisk?.textColor ?? UIColor.red,
            NSAttributedString.Key.font: collectInput.labelStyles.requiredAstrisk?.font ?? UIFont.boldSystemFont(ofSize: 18.0),
            .baselineOffset:  verticalAstrisk > 0.0 ? verticalAstrisk : 2.0
        ]
        
        var leftAstriskPadding = Double(collectInput.labelStyles.requiredAstrisk?.padding?.left ?? 0.0)
        
        
        leftAstriskPadding = leftAstriskPadding / 2
        
        
        DispatchQueue.main.async {
            let attributedString = NSMutableAttributedString(string:text)
            let asterisk = NSAttributedString(string: " *", attributes: astriskAttributes)
            let space = NSAttributedString(string: " ")
            
            
            while leftAstriskPadding > 0 {
                attributedString.append(space)
                leftAstriskPadding-=1
            }
            
            if(self.isRequired)
            {
                
                attributedString.append(asterisk)
            }
            self.textFieldLabel.attributedText = attributedString;
        }
        
        
        
        stackView.addArrangedSubview(textFieldLabel)
        stackView.addArrangedSubview(textField)
        if contextOptions.interface != .COMPOSABLE_CONTAINER {
            stackView.addArrangedSubview(errorMessage)
        }

        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        setMainPaddings()
    }
    
    @objc
    func addTextFieldObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldDidChange), name: UITextField.textDidChangeNotification, object: textField)
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
    }
    
    @objc
    func focusOn() {
        textField.becomeFirstResponder()
        onFocusIsTrue?()
        textFieldValueChanged()
        
    }
}

extension TextField {
    public func setError(_ error: String) {
        self.errorTriggered = true
        self.errorMessage.text = error
        updateErrorMessage()
    }
    
    public func resetError() {
        self.errorMessage.text = ""
        self.errorTriggered = false
        updateErrorMessage()
    }
    
    public func getID() -> String {
        return uuid;
    }
}

