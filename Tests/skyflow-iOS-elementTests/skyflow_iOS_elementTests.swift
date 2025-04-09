/*
 * Copyright (c) 2022 Skyflow
*/


import XCTest
import UIKit
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
        
        skyflowElement = SkyflowElement(input: collectInput!, options: collectOptions!, contextOptions: ContextOptions(), elements: [] )
        
        textField = TextField(input: collectInput, options: collectOptions, contextOptions: ContextOptions(), elements: [])

        let revealElementInput = RevealElementInput(token: "token", label: "RevealElement", redaction: .DEFAULT)
        label = Label(input: revealElementInput, options: RevealElementOptions())
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
    func testStyleOnFocusElement(){
        skyflowElement.collectInput.inputStyles.focus?.borderColor = .red
        skyflowElement.collectInput.inputStyles.empty?.borderColor = .blue
        skyflowElement.collectInput.inputStyles.focus?.textColor = .red
        XCTAssertEqual(skyflowElement.collectInput.inputStyles.focus?.borderColor, .red)
        XCTAssertEqual(skyflowElement.collectInput.inputStyles.focus?.textColor, .red)
        XCTAssertEqual(skyflowElement.collectInput.inputStyles.empty?.borderColor, .blue)
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
        let textField = TextField(input: collectInput, options: collectOptions, contextOptions: ContextOptions(), elements: [])

        textField.textField.secureText = "invalid"
        textField.textFieldDidEndEditing(textField.textField)
        XCTAssertEqual(textField.errorMessage.alpha, 1.0)
        XCTAssertEqual(textField.errorMessage.text, "Invalid value")
    }
    
    func testCustomRegexValidationFailureOnUI() {
        let myRegexRule = RegexMatchRule(regex: "\\d+", error: "Regex match failed")
        let myRandomRule = LengthMatchRule(minLength: 5, maxLength: 10)
        let myRules = ValidationSet(rules: [myRandomRule, myRegexRule])
        
        
        let collectInput = CollectElementInput(table: "tablename", column: "column", placeholder: "John Doe", type: .INPUT_FIELD, validations: myRules)
        let textField = TextField(input: collectInput, options: collectOptions, contextOptions: ContextOptions(), elements: [])


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
        let textField = TextField(input: collectInput, options: collectOptions, contextOptions: ContextOptions(), elements: [])

        textField.textField.secureText = "4111111111111111"
        textField.textFieldDidEndEditing(textField.textField)
        XCTAssertEqual(textField.errorMessage.alpha, 0.0)
    }
    
    func testTriggerError() {
        let errorStyle = Style(textColor: .red)
        let inputStyle = Styles(invalid: errorStyle)
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", inputStyles: inputStyle, placeholder: "card number", type: .CARD_NUMBER)
        let textField = TextField(input: collectInput, options: collectOptions, contextOptions: ContextOptions(), elements: [])

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
        let textField = TextField(input: collectInput, options: collectOptions, contextOptions: ContextOptions(), elements: [])

        textField.textField.secureText = "invalid"
        textField.setError("triggered error")
        textField.textFieldDidEndEditing(textField.textField)
        textField.resetError()
        
        XCTAssertEqual(textField.errorMessage.alpha, 1.0)
        XCTAssertEqual(textField.errorMessage.text, "Invalid value")
        XCTAssertEqual(textField.textField.textColor, errorStyle.textColor)
    }
    
    func testCardExpiryValidationMMYY() {
        let mmyy = "12/24"
        
        let cardexpValidation = SkyflowValidateCardExpirationDate(format: "mm/yy", error: "Invalid Card expiration date")
        XCTAssertTrue(SkyflowValidator.validate(input: mmyy, rules: ValidationSet(rules: [cardexpValidation])).isEmpty)
    }
    
    func testCardExpiryValidationMMYYYY() {
        let mmyyyy = "12/2029"
        
        let cardexpValidation = SkyflowValidateCardExpirationDate(format: "mm/yyyy", error: "Invalid Card expiration date")
        XCTAssertTrue(SkyflowValidator.validate(input: mmyyyy, rules: ValidationSet(rules: [cardexpValidation])).isEmpty)
    }
    
    func testCardExpiryValidationYYMM() {
        let yymm = "28/12"
        
        let cardexpValidation = SkyflowValidateCardExpirationDate(format: "yy/mm", error: "Invalid Card expiration date")
        XCTAssertTrue(SkyflowValidator.validate(input: yymm, rules: ValidationSet(rules: [cardexpValidation])).isEmpty)
    }
    
    func testCardExpiryValidationYYYYMM() {
        let yyyymm = "2028/12"
        
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
    func testLabelSetTokenActualValueCheck() {
        let dummyToken = "dummyToken"
        self.label.setToken(dummyToken)
        
        XCTAssertEqual(self.label.getToken(), dummyToken)
        XCTAssertEqual(self.label.skyflowLabelView.label.actualValue, "")
    }
    
    func testLabelSetAltText() {
        let dummyAltText = "dummyAltText"
        self.label.setAltText(dummyAltText)
        
        XCTAssertEqual(self.label.revealInput.token, "token")
        XCTAssertEqual(self.label.skyflowLabelView.label.secureText, dummyAltText)
    }
    func testLabelSetAltTextActualValueCheck() {
        let dummyAltText = "dummyAltText"
        self.label.setAltText(dummyAltText)
        
        XCTAssertEqual(self.label.revealInput.token, "token")
        XCTAssertEqual(self.label.skyflowLabelView.label.secureText, dummyAltText)
        XCTAssertEqual(self.label.skyflowLabelView.label.actualValue, "")

    }

    func testLabelClearAltText() {
        self.label.clearAltText()
        
        XCTAssertEqual(self.label.revealInput.token, "token")
        XCTAssertEqual(self.label.skyflowLabelView.label.secureText, "token")
    }
    func testLabelClearAltTextActualValueCheck() {
        self.label.clearAltText()
        
        XCTAssertEqual(self.label.revealInput.token, "token")
        XCTAssertEqual(self.label.skyflowLabelView.label.secureText, "token")
        XCTAssertEqual(self.label.skyflowLabelView.label.actualValue, "")

    }
    func testExpiryYearValidationYY() {
        
        let yearValidation = SkyflowValidateExpirationYear(format: "yy", error: SkyflowValidationErrorType.expirationYear.rawValue)
        
        XCTAssertFalse(yearValidation.validate("234"))
        XCTAssertTrue(yearValidation.validate("27"))

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
    func getElementForDropDownTesting()-> TextField {
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER)
        let textField = TextField(input: collectInput, options: collectOptions, contextOptions: ContextOptions(), elements: [])
        textField.textField.secureText = "4111111111111111"

        return textField
    }
    func getElementForDropDownTestingRightIcon()-> TextField {
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", iconStyles: Styles(base: Style(cardIconAlignment: .right)),placeholder: "card number", type: .CARD_NUMBER)
        let textField = TextField(input: collectInput, options: CollectElementOptions(enableCardIcon: true, enableCopy: true), contextOptions: ContextOptions(), elements: [])
        textField.textField.secureText = "4111111111111111"
        return textField
    }
    func getElementOfOtherType()-> TextField {
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", iconStyles: Styles(base: Style(cardIconAlignment: .right)),placeholder: "card number", type: .CVV)
        let textField = TextField(input: collectInput, options: CollectElementOptions(enableCopy: true), contextOptions: ContextOptions(), elements: [])
        textField.textField.secureText = "1234"
        return textField
    }
    func testDropdownVisible() {
        let textField = getElementForDropDownTesting()

        textField.textFieldDidEndEditing(textField.textField)
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": [CardType.AMEX, CardType.VISA]]))
        XCTAssertEqual(textField.selectedCardBrand?.instance.defaultName, CardType.AMEX.instance.defaultName)
        XCTAssertTrue(textField.listCardTypes?.count == 2)
        XCTAssertEqual(textField.listCardTypes, [CardType.AMEX, CardType.VISA])
        XCTAssertTrue(textField.dropdownButton.isHidden == false)
    }
    func testDropdownVisibleWhenCardPosIsRight() {
        let textField = getElementForDropDownTestingRightIcon()
        
        textField.textFieldDidEndEditing(textField.textField)
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": [CardType.AMEX, CardType.VISA]]))
        XCTAssertEqual(textField.selectedCardBrand?.instance.defaultName, CardType.AMEX.instance.defaultName)
        XCTAssertTrue(textField.listCardTypes?.count == 2)
        XCTAssertEqual(textField.listCardTypes, [CardType.AMEX, CardType.VISA])
        XCTAssertTrue(textField.dropdownButton.isHidden == false)
    }
    func testDropdownNotVisibleWhenCardPosIsRight() {
        let textField = getElementForDropDownTestingRightIcon()

        textField.textFieldDidEndEditing(textField.textField)
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": [CardType.AMEX, CardType.VISA]]))
        XCTAssertEqual(textField.selectedCardBrand?.instance.defaultName, CardType.AMEX.instance.defaultName)
        XCTAssertTrue(textField.listCardTypes != nil)
        XCTAssertEqual(textField.listCardTypes, [CardType.AMEX, CardType.VISA])
        XCTAssertFalse(textField.dropdownButton.isHidden)
        
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": []]))
        XCTAssertTrue(textField.selectedCardBrand == nil)
        XCTAssertTrue(textField.listCardTypes == nil)
        XCTAssertEqual(textField.listCardTypes, nil)
        XCTAssertTrue(textField.dropdownButton.isHidden)
    }
    func testEnableCopyForOtherElements() {
        let textField = getElementOfOtherType()

        textField.textFieldDidEndEditing(textField.textField)
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": [CardType.AMEX, CardType.VISA]]))
        XCTAssertTrue(textField.selectedCardBrand == nil)
        XCTAssertEqual(textField.listCardTypes, nil)
        XCTAssertFalse(textField.dropdownButton.isHidden)
        
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": []]))
        XCTAssertTrue(textField.selectedCardBrand == nil)
        XCTAssertTrue(textField.listCardTypes == nil)
        XCTAssertEqual(textField.listCardTypes, nil)
    }
    func testDropdownNotVisible() {
        let textField = getElementForDropDownTesting()

        textField.textFieldDidEndEditing(textField.textField)
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": [CardType.AMEX, CardType.VISA]]))
        XCTAssertEqual(textField.selectedCardBrand?.instance.defaultName, CardType.AMEX.instance.defaultName)
        XCTAssertTrue(textField.listCardTypes != nil)
        XCTAssertEqual(textField.listCardTypes, [CardType.AMEX, CardType.VISA])
        XCTAssertFalse(textField.dropdownButton.isHidden)
        
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": []]))
        XCTAssertTrue(textField.selectedCardBrand == nil)
        XCTAssertTrue(textField.listCardTypes == nil)
        XCTAssertEqual(textField.listCardTypes, nil)
        XCTAssertTrue(textField.dropdownButton.isHidden)
    }
    func testDropdownUpdateOptions() {
        let textField = getElementForDropDownTesting()

        textField.textFieldDidEndEditing(textField.textField)
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": []]))
        XCTAssertTrue(textField.selectedCardBrand == nil)
        XCTAssertTrue(textField.listCardTypes == nil)
        XCTAssertEqual(textField.listCardTypes, nil)
        XCTAssertTrue(textField.dropdownButton.isHidden)
    }
    func testDropdownNotVisibleOneScheme() {
        let textField = getElementForDropDownTesting()

        textField.textFieldDidEndEditing(textField.textField)
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": [CardType.AMEX]]))
        XCTAssertTrue(textField.dropdownButton.isHidden)
    }
    func testDropdownClick() {
        let textField = getElementForDropDownTesting()

        textField.textFieldDidEndEditing(textField.textField)
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": [CardType.AMEX, CardType.VISA]]))
        XCTAssertFalse(textField.dropdownButton.isHidden)
        XCTAssertEqual(textField.selectedCardBrand?.instance.defaultName, CardType.AMEX.instance.defaultName)
    }
    func testDropdownClickAndMenuVisible() {
        let textField = getElementForDropDownTesting()

        textField.textFieldDidEndEditing(textField.textField)
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": [CardType.AMEX, CardType.VISA]]))
        XCTAssertFalse(textField.dropdownButton.isHidden)
        XCTAssertEqual(textField.selectedCardBrand?.instance.defaultName, CardType.AMEX.instance.defaultName)
        if #available(iOS 14.0, *) {
            XCTAssertEqual(textField.dropdownButton.menu?.children.count, 2)
            XCTAssertEqual((textField.dropdownButton.menu?.children.first as? UIAction)?.title, CardType.AMEX.instance.defaultName)
            XCTAssertEqual((textField.dropdownButton.menu?.children.last as? UIAction)?.title, CardType.VISA.instance.defaultName)
        }
    }

    func getElementForDropDownTestingWindow() -> TextField {
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER)
        let textField = TextField(input: collectInput, options: collectOptions, contextOptions: ContextOptions(), elements: [])
        textField.textField.secureText = "4111111111111111"
        return textField
    }
    func testShowDropdown() {
        let textField = getElementForDropDownTestingWindow()
        textField.textFieldDidEndEditing(textField.textField)
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": [CardType.AMEX]]))
        
        textField.listCardTypes = [.AMEX] 
        
        XCTAssertTrue(textField.dropdownButton.isHidden)
     }
    func testGetDropDownIconSetsUpButton() {
        let textField = getElementForDropDownTestingWindow()
        textField.textFieldDidEndEditing(textField.textField)
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": [CardType.AMEX, CardType.VISA]]))
        XCTAssertEqual(textField.selectedCardBrand?.instance.defaultName, CardType.AMEX.instance.defaultName)
        if #available(iOS 14.0, *) {
            XCTAssertEqual(textField.dropdownButton.frame, CGRect(x: 50, y: 15, width: 12, height: 15))
            XCTAssertFalse(textField.dropdownButton.isHidden)
        } else {
            XCTAssertEqual(textField.dropdownButton.frame, CGRect(x: 50, y: 15, width: 12, height: 15))
            XCTAssertFalse(textField.dropdownButton.isHidden)
        }
    }
    
    func testDisableCardIconWhenEnableCopyTrue(){
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER)
        let textField = TextField(input: collectInput, options: CollectElementOptions(enableCardIcon: false, enableCopy: true), contextOptions: ContextOptions(), elements: [])
        textField.textField.secureText = "4111111111111111"
        textField.textFieldDidEndEditing(textField.textField)
        XCTAssertTrue(textField.cardIconContainerView.isHidden)
    }
    func testDisableCardIconWhenEnableCopyFalse(){
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER)
        let textField = TextField(input: collectInput, options: CollectElementOptions(enableCardIcon: false, enableCopy: false), contextOptions: ContextOptions(), elements: [])
        textField.textField.secureText = "4111111111111111"
        textField.textFieldDidEndEditing(textField.textField)
        XCTAssertTrue(textField.cardIconContainerView.isHidden)
    }
    @available(iOS 14.0, *)
    func testMenuHasCorrectItems() {
        // Arrange
        let expectedTitles = CardType.allCases.map { $0.instance.defaultName }
        let textField = getElementForDropDownTestingWindow()
        textField.textFieldDidEndEditing(textField.textField)
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": [CardType.AMEX]]))
        XCTAssertNil(textField.dropdownButton.menu)
        XCTAssertEqual(1, textField.listCardTypes?.count)

        
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": [CardType.AMEX, .MASTERCARD]]))
        
        let menu = textField.dropdownButton.menu
        
        XCTAssertNotNil(menu)
        XCTAssertEqual(menu?.children.count, textField.listCardTypes?.count)
        
        for child in menu!.children {
            guard let action = child as? UIAction else {
                XCTFail("Expected UIAction type in menu children")
                return
            }
        }
    }
    @available(iOS 14.0, *)
    func testMenuHasCorrectItemsMenu() {
        // Arrange
        let expectedTitles = CardType.allCases.map { $0.instance.defaultName }
        let textField = getElementForDropDownTestingWindow()
        textField.textFieldDidEndEditing(textField.textField)
        
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": [CardType.AMEX, .MASTERCARD]]))
        let menu = textField.dropdownButton.menu
        textField.setUpMenuView()
        textField.updateMenuView()
        XCTAssertNotNil(menu)
        XCTAssertEqual(menu?.children.count, textField.listCardTypes?.count)
        textField.selectedCardBrand = CardType.AMEX
        textField.setUpMenuView()
        textField.updateMenuView()
        for child in menu!.children {
            guard let action = child as? UIAction else {
                return
            }
            if (action.title == CardType.AMEX.instance.defaultName) {
                action.state = .on
            }
        }
        XCTAssertEqual(textField.selectedCardBrand?.instance.defaultName, CardType.AMEX.instance.defaultName)
    }
    func testGetDropDownIconSetsUpButtonRightView() {
        let textField = getElementForDropDownTestingRightIcon()
        textField.textFieldDidEndEditing(textField.textField)
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": [CardType.AMEX]]))
        if #available(iOS 14.0, *) {
            XCTAssertEqual(textField.dropdownButton.frame, CGRect(x: 0, y: 0, width: 0, height: 0))
            XCTAssertTrue(textField.dropdownButton.isHidden)
            XCTAssertEqual(textField.cardIconContainerView.frame, CGRect(x: 0, y: 0, width: 100.0, height: 40))
        }
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": [CardType.AMEX, .VISA]]))
        if #available(iOS 14.0, *) {
            XCTAssertEqual(textField.dropdownButton.frame, CGRect(x: 50, y: 15, width: 12, height: 15))
            XCTAssertFalse(textField.dropdownButton.isHidden)
            XCTAssertEqual(textField.cardIconContainerView.frame, CGRect(x: 0, y: 0, width: 100, height: 40))
        }
    }
    func testGetDropDownIconSetsUpButtonLeftView() {
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", iconStyles: Styles(base: Style(cardIconAlignment: .left)),placeholder: "card number", type: .CARD_NUMBER)
        let textField = TextField(input: collectInput, options: CollectElementOptions(enableCardIcon: true, enableCopy: true), contextOptions: ContextOptions(), elements: [])
        textField.textField.secureText = "4111111111111111"
        
        textField.textFieldDidEndEditing(textField.textField)
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": [CardType.AMEX]]))
        if #available(iOS 14.0, *) {
            XCTAssertEqual(textField.dropdownButton.frame, CGRect(x: 0, y: 0, width: 0, height: 0))
            XCTAssertTrue(textField.dropdownButton.isHidden)
            XCTAssertEqual(textField.cardIconContainerView.frame, CGRect(x: 0, y: 0, width: 60, height: 40))
        }
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": [CardType.AMEX, .VISA]]))
        if #available(iOS 14.0, *) {
            XCTAssertEqual(textField.dropdownButton.frame, CGRect(x: 50, y: 15, width: 12, height: 15))
            XCTAssertFalse(textField.dropdownButton.isHidden)
            XCTAssertEqual(textField.cardIconContainerView.frame, CGRect(x: 0, y: 0, width: 62, height: 40))
        }
    }
    func testGetDropDownIconSetsUpButtonRightViewEnableCopyFalse() {
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", iconStyles: Styles(base: Style(cardIconAlignment: .right)),placeholder: "card number", type: .CARD_NUMBER)
        let textField = TextField(input: collectInput, options: CollectElementOptions(enableCardIcon: true, enableCopy: false), contextOptions: ContextOptions(), elements: [])
        textField.textField.secureText = "4111111111111111";        textField.textFieldDidEndEditing(textField.textField)
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": [CardType.AMEX]]))
        if #available(iOS 14.0, *) {
            XCTAssertEqual(textField.dropdownButton.frame, CGRect(x: 0, y: 0, width: 0, height: 0))
            XCTAssertTrue(textField.dropdownButton.isHidden)
            XCTAssertEqual(textField.cardIconContainerView.frame, CGRect(x: 0, y: 0, width: 65, height: 40))
        }
        textField.update(updateOptions: CollectElementOptions(cardMetaData: ["scheme": [CardType.AMEX, .VISA]]))
        if #available(iOS 14.0, *) {
            XCTAssertEqual(textField.dropdownButton.frame, CGRect(x: 50, y: 15, width: 12, height: 15))
            XCTAssertFalse(textField.dropdownButton.isHidden)
            XCTAssertEqual(textField.cardIconContainerView.frame, CGRect(x: 0, y: 0, width: 79, height: 40))
        }
    }
}
