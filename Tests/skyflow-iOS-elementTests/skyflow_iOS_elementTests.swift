
import XCTest
@testable import Skyflow


class skyflow_iOS_elementTests: XCTestCase {

    var collectOptions: CollectElementOptions!
    var collectInput: CollectElementInput!
    var label: SkyflowElement!
    var textField: TextField!
    
    override func setUp() {
        
        self.collectOptions = CollectElementOptions(required: false)
        
        self.collectInput = CollectElementInput(table: "persons", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER)
        
        
        label = SkyflowElement(input: collectInput!, options: collectOptions!, contextOptions: ContextOptions())
        
        textField = TextField(input: collectInput, options: collectOptions, contextOptions: ContextOptions())
    }
    
    override func tearDown() {
        self.collectInput = nil
        self.collectOptions = nil
        label = nil
    }
    
    func testSkyflowElementState() {
        XCTAssertEqual(label.getState()["columnName"] as! String, "cardNumber")
        XCTAssertEqual(label.getState()["isRequired"] as! Bool, false)
    }
    
    func testSkyflowElementDefaults() {
        XCTAssertNotNil(label.borderColor)
        XCTAssertEqual(label.borderWidth, 0.0)
        XCTAssertEqual(label.cornerRadius, 0.0)
    }
    
    func testSkyflowElementValidate() {
        label.borderColor = .blue
        label.borderWidth = 1.0
        label.cornerRadius = 1.2
        label.padding = UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 3.0)
        
        
        XCTAssertEqual(label.borderWidth, 1.0)
        XCTAssertEqual(label.cornerRadius, 1.2)
        XCTAssertEqual(label.padding, UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 3.0))
        XCTAssertEqual(label.borderColor, .blue)
        
        XCTAssertEqual(label.validate().count, 0)
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
        var appendToThis = ValidationSet(rules: [SkyflowValidateLength(minLength: 2, maxLength: 3, error: "not in bounds")])
        
        appendToThis.append(ruleSet)
        XCTAssertEqual(appendToThis.rules.count, 2)
        XCTAssertEqual(appendToThis.rules[1].error, ruleSet.rules[0].error)
    }
    
    func testCustomRegexValidationFailure() {
        let myRegexRule = SkyflowValidatePattern(regex: "\\d+", error: "Regex match failed")
        let myRules = ValidationSet(rules: [myRegexRule])
        
        
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER, validations: myRules)
        let textField = TextField(input: collectInput, options: collectOptions, contextOptions: ContextOptions())

        textField.textField.secureText = "invalid"
        textField.textFieldDidEndEditing(textField.textField)
        XCTAssertEqual(textField.errorMessage.alpha, 1.0)
    }
    
    func testCustomRegexValidationSuccess() {
        let myRegexRule = SkyflowValidatePattern(regex: "\\d+", error: "Regex match failed")
        let myRules = ValidationSet(rules: [myRegexRule])
        
        
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER, validations: myRules)
        let textField = TextField(input: collectInput, options: collectOptions, contextOptions: ContextOptions())

        textField.textField.secureText = "424242"
        textField.textFieldDidEndEditing(textField.textField)
        XCTAssertEqual(textField.errorMessage.alpha, 0.0)
    }

}
