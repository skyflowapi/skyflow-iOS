/*
 * Copyright (c) 2022 Skyflow
 */


import XCTest
@testable import Skyflow

// swiftlint:disable:next type_body_length
class skyflow_iOS_elementTests: XCTestCase {
    
    var collectOptions: CollectElementOptions!
    var collectInput: CollectElementInput!
    var skyflowElement: SkyflowElement!
    var textField: TextField!
    var label: Label!
    
    override func setUp() {
        
        self.collectOptions = CollectElementOptions(required: false)
        
        self.collectInput = CollectElementInput(table: "persons", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER)
        
        
        skyflowElement = SkyflowElement(input: collectInput!, options: collectOptions!, contextOptions: ContextOptions())
        
        textField = TextField(input: collectInput, options: collectOptions, contextOptions: ContextOptions())
        
        let revealElementInput = RevealElementInput(token: "token", label: "RevealElement", redaction: .DEFAULT)
        label = Label(input: revealElementInput)
    }
    
    override func tearDown() {
        self.collectInput = nil
        self.collectOptions = nil
        label = nil
        skyflowElement = nil
    }
    
    func testSkyflowElementState() {
        XCTAssertEqual(skyflowElement.getState()["columnName"] as! String, "cardNumber")
        XCTAssertEqual(skyflowElement.getState()["isRequired"] as! Bool, false)
    }
    
    func testSkyflowElementDefaults() {
        XCTAssertNotNil(skyflowElement.borderColor)
        XCTAssertEqual(skyflowElement.borderWidth, 0.0)
        XCTAssertEqual(skyflowElement.cornerRadius, 0.0)
    }
    
    func testSkyflowElementValidate() {
        skyflowElement.borderColor = .blue
        skyflowElement.borderWidth = 1.0
        skyflowElement.cornerRadius = 1.2
        skyflowElement.padding = UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 3.0)
        
        
        XCTAssertEqual(skyflowElement.borderWidth, 1.0)
        XCTAssertEqual(skyflowElement.cornerRadius, 1.2)
        XCTAssertEqual(skyflowElement.padding, UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 3.0))
        XCTAssertEqual(skyflowElement.borderColor, .blue)
        
        XCTAssertEqual(skyflowElement.validate().count, 0)
    }
    
    func testTextFieldDefaults() {
        XCTAssertNil(textField.textFieldBorderColor)
        XCTAssertNotNil(textField.borderColor)
        XCTAssertEqual(textField.isMounted(), false)
        XCTAssertEqual(textField.textFieldBorderWidth, 0)
        XCTAssertEqual(textField.textFieldCornerRadius, 0)
        XCTAssertEqual(textField.hasFocus, false)
        XCTAssertEqual(textField.getValue(), "")
        XCTAssertEqual(textField.errorMessage.alpha, 0)
        XCTAssertEqual(textField.getOutput(), "")
        XCTAssertEqual(textField.isDirty, false)
        XCTAssertEqual(textField.isFirstResponder, false)
    }
    
    func testTextFieldFirstResponder() {
        self.textField.becomeFirstResponder()
        XCTAssertEqual(self.textField.hasBecomeResponder, true)
        self.textField.resignFirstResponder()
        XCTAssertEqual(self.textField.hasBecomeResponder, false)
    }
    
    func testTextFieldState() {
        let window = UIWindow()
        window.addSubview(textField)
        
        XCTAssertEqual(textField.state.isRequired, false)
        XCTAssertEqual(textField.state.getState()["isValid"] as! Bool, true)
        XCTAssertEqual(textField.isValid(), true)
        XCTAssertEqual(textField.isMounted(), true)
    }
    
    func testTextFieldErrorOnEdit() {
        textField.textField.secureText = "invalidcard"
        textField.updateActualValue()
        self.textField.textFieldDidEndEditing(self.textField.textField)
        XCTAssertEqual(self.textField.isErrorMessageShowing, true)
    }
    
    func testTextFieldSuccessOnEdit() {
        textField.textField.secureText = "4111-1111-1111-1111"
        textField.updateActualValue()
        self.textField.textFieldDidEndEditing(self.textField.textField)
        XCTAssertEqual(self.textField.isErrorMessageShowing, false)
        
    }
    
    func testValidationSetApend() {
        let ruleSet = ValidationSet(rules: [SkyflowValidateLengthMatch(lengths: [2, 3], error: "bad length")])
        var appendToThis = ValidationSet(rules: [LengthMatchRule(minLength: 2, maxLength: 3, error: "not in bounds")])
        
        appendToThis.append(ruleSet)
        XCTAssertEqual(appendToThis.rules.count, 2)
        XCTAssertEqual(appendToThis.rules[1].error, ruleSet.rules[0].error)
    }
    
    func testCustomRegexValidationFailure() {
        let myRegexRule = RegexMatchRule(regex: "\\d+", error: "Regex match failed")
        let myRules = ValidationSet(rules: [myRegexRule])
        
        
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER, validations: myRules)
        let textField = TextField(input: collectInput, options: collectOptions, contextOptions: ContextOptions())
        
        textField.textField.secureText = "invalid"
        textField.textFieldDidEndEditing(textField.textField)
        XCTAssertEqual(textField.errorMessage.alpha, 1.0)
        XCTAssertEqual(textField.errorMessage.text, "Invalid element")
    }
    
    func testCustomRegexValidationFailureOnUI() {
        let myRegexRule = RegexMatchRule(regex: "\\d+", error: "Regex match failed")
        let myRandomRule = LengthMatchRule(minLength: 5, maxLength: 10)
        let myRules = ValidationSet(rules: [myRandomRule, myRegexRule])
        
        
        let collectInput = CollectElementInput(table: "tablename", column: "column", placeholder: "John Doe", type: .INPUT_FIELD, validations: myRules)
        let textField = TextField(input: collectInput, options: collectOptions, contextOptions: ContextOptions())
        
        // Default UI error
        textField.textField.secureText = "John"
        textField.textFieldDidEndEditing(textField.textField)
        XCTAssertEqual(textField.errorMessage.alpha, 1.0)
        XCTAssertEqual(textField.errorMessage.text, "Validation failed")
        
        // Render user defined error in UI
        textField.textField.secureText = "John Doe"
        textField.textFieldDidEndEditing(textField.textField)
        XCTAssertEqual(textField.errorMessage.alpha, 1.0)
        XCTAssertEqual(textField.errorMessage.text, "Regex match failed")
    }
    
    
    func testCustomRegexValidationSuccess() {
        let myRegexRule = RegexMatchRule(regex: "\\d+", error: "Regex match failed")
        let myRules = ValidationSet(rules: [myRegexRule])
        
        
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER, validations: myRules)
        let textField = TextField(input: collectInput, options: collectOptions, contextOptions: ContextOptions())
        
        textField.textField.secureText = "4111111111111111"
        textField.textFieldDidEndEditing(textField.textField)
        XCTAssertEqual(textField.errorMessage.alpha, 0.0)
    }
    
    func testTriggerError() {
        let errorStyle = Style(textColor: .red)
        let inputStyle = Styles(invalid: errorStyle)
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", inputStyles: inputStyle, placeholder: "card number", type: .CARD_NUMBER)
        let textField = TextField(input: collectInput, options: collectOptions, contextOptions: ContextOptions())
        
        textField.textField.secureText = "invalid"
        textField.setError("triggered error")
        textField.textFieldDidEndEditing(textField.textField)
        XCTAssertEqual(textField.errorMessage.alpha, 1.0)
        // Takes precendence over all errors
        XCTAssertEqual(textField.errorMessage.text, "triggered error")
        XCTAssertEqual(textField.textField.textColor, errorStyle.textColor)
    }
    
    func testResetError() {
        let errorStyle = Style(textColor: .red)
        let inputStyle = Styles(invalid: errorStyle)
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", inputStyles: inputStyle, placeholder: "card number", type: .CARD_NUMBER)
        let textField = TextField(input: collectInput, options: collectOptions, contextOptions: ContextOptions())
        
        textField.textField.secureText = "invalid"
        textField.setError("triggered error")
        textField.textFieldDidEndEditing(textField.textField)
        textField.resetError()
        
        XCTAssertEqual(textField.errorMessage.alpha, 1.0)
        XCTAssertEqual(textField.errorMessage.text, "Invalid element")
        XCTAssertEqual(textField.textField.textColor, errorStyle.textColor)
    }
    
    func testCardExpiryValidationMMYY() {
        let mmyy = "12/23"
        
        let cardexpValidation = SkyflowValidateCardExpirationDate(format: "mm/yy", error: "Invalid Card expiration date")
        XCTAssertTrue(SkyflowValidator.validate(input: mmyy, rules: ValidationSet(rules: [cardexpValidation])).isEmpty)
    }
    
    func testCardExpiryValidationMMYYYY() {
        let mmyyyy = "12/2023"
        
        let cardexpValidation = SkyflowValidateCardExpirationDate(format: "mm/yyyy", error: "Invalid Card expiration date")
        XCTAssertTrue(SkyflowValidator.validate(input: mmyyyy, rules: ValidationSet(rules: [cardexpValidation])).isEmpty)
    }
    
    func testCardExpiryValidationYYMM() {
        let yymm = "23/12"
        
        let cardexpValidation = SkyflowValidateCardExpirationDate(format: "yy/mm", error: "Invalid Card expiration date")
        XCTAssertTrue(SkyflowValidator.validate(input: yymm, rules: ValidationSet(rules: [cardexpValidation])).isEmpty)
    }
    
    func testCardExpiryValidationYYYYMM() {
        let yyyymm = "2023/12"
        
        let cardexpValidation = SkyflowValidateCardExpirationDate(format: "yyyy/mm", error: "Invalid Card expiration date")
        XCTAssertTrue(SkyflowValidator.validate(input: yyyymm, rules: ValidationSet(rules: [cardexpValidation])).isEmpty)
    }
    
    func testCardExpiryValidationFailure() {
        let mmyy = "12/23"
        
        let cardexpValidation = SkyflowValidateCardExpirationDate(format: "ab/y", error: "Invalid Card expiration date")
        XCTAssertFalse(SkyflowValidator.validate(input: mmyy, rules: ValidationSet(rules: [cardexpValidation])).isEmpty)
    }
    
    func testLabelSetToken() {
        let dummyToken = "dummyToken"
        self.label.setToken(dummyToken)
        
        XCTAssertEqual(self.label.getToken(), dummyToken)
    }
    
    func testLabelSetAltText() {
        let dummyAltText = "dummyAltText"
        self.label.setAltText(dummyAltText)
        
        XCTAssertEqual(self.label.revealInput.token, "token")
        XCTAssertEqual(self.label.skyflowLabelView.label.secureText, dummyAltText)
    }
    
    func testLabelClearAltText() {
        self.label.clearAltText()
        
        XCTAssertEqual(self.label.revealInput.token, "token")
        XCTAssertEqual(self.label.skyflowLabelView.label.secureText, "token")
    }
    
    func testExpiryYearValidationYY() {
        
        let yearValidation = SkyflowValidateExpirationYear(format: "yy", error: SkyflowValidationErrorType.expirationYear.rawValue)
        
        XCTAssertFalse(yearValidation.validate("234"))
        XCTAssertTrue(yearValidation.validate("23"))
        
    }
    
    func testExpiryYearValidationYYYY() {
        
        let yearValidation = SkyflowValidateExpirationYear(format: "yyyy", error: SkyflowValidationErrorType.expirationYear.rawValue)
        
        XCTAssertFalse(yearValidation.validate("1234"))
        XCTAssertFalse(yearValidation.validate("2132"))
        XCTAssertFalse(yearValidation.validate("22"))
        XCTAssertTrue(yearValidation.validate("2032"))
        
    }
    
    func testExpiryMonthValidation() {
        
        let yearValidation = SkyflowValidateExpirationMonth(error: SkyflowValidationErrorType.expirationYear.rawValue)
        
        XCTAssertFalse(yearValidation.validate("24"))
        XCTAssertTrue(yearValidation.validate("12"))
        XCTAssertTrue(yearValidation.validate("01"))
        
    }
    
}
