import XCTest
import Foundation
@testable import Skyflow

// swiftlint:disable:next type_body_length
class InputFormattingTests: XCTestCase {
    
    var skyflow: Client!

    override func setUp() {
        self.skyflow = Skyflow.initialize(
            Configuration(vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!,
                          vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!,
                          tokenProvider: DemoTokenProvider())
        )
    }
    
    func getCardNumberElement() -> TextField?{
        
        let window = UIWindow()
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let cardNumberInput = CollectElementInput(table: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: cardNumberInput, options: options)
        window.addSubview(cardNumber!)
        
        return cardNumber
    }
    
    func getexpiryDateElement() -> TextField?{
        
        let window = UIWindow()
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let expiryDateInput = CollectElementInput(table: "persons", column: "cvv", placeholder: "expiryDate", type: .EXPIRATION_DATE)
        
        let expiryDate = container?.create(input: expiryDateInput, options: options)
        window.addSubview(expiryDate!)
        
        return expiryDate
    }
    
    func getExpiryMonthElement() -> TextField?{
        
        let window = UIWindow()
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let expiryDateInput = CollectElementInput(table: "persons", column: "cvv", placeholder: "expiryDate", type: .EXPIRATION_MONTH)
        
        let expiryDate = container?.create(input: expiryDateInput, options: options)
        window.addSubview(expiryDate!)
        
        return expiryDate
    }
    
    func testCardNumberFormattingNewChar() {
        let cardNumber = getCardNumberElement()

        let currentText = "4111 1111 1111 111"
        cardNumber?.textField.secureText = currentText
        let result = cardNumber?.textField.delegate?.textField?(
            cardNumber!.textField,
            shouldChangeCharactersIn: NSRange(currentText.endIndex..<currentText.endIndex, in: currentText),
            replacementString: "1")
        
        XCTAssertFalse(result!)
        XCTAssertEqual(cardNumber?.actualValue, "4111111111111111")
        XCTAssertEqual(cardNumber?.textField.secureText, currentText+"1")
    }
    
    func testCardNumberFormattingBackspace() {
        let cardNumber = getCardNumberElement()

        let currentText = "4111 1111 1111 1"
        cardNumber?.textField.secureText = currentText
        let lastIndex = currentText.index(before: currentText.endIndex)
        let result = cardNumber?.textField.delegate?.textField?(
            cardNumber!.textField,
            shouldChangeCharactersIn: NSRange(lastIndex..<currentText.endIndex, in: currentText),
            replacementString: "")
        
        
        XCTAssertFalse(result!)
        XCTAssertEqual(cardNumber?.actualValue, "411111111111")
        XCTAssertEqual(cardNumber?.textField.secureText, "4111 1111 1111")
    }
    
    func testExpiryDateFormattingNewChar() {
        let expiryDate = getexpiryDateElement()

        let currentText = "23"
        expiryDate?.textField.secureText = currentText
        let result = expiryDate?.textField.delegate?.textField?(
            expiryDate!.textField,
            shouldChangeCharactersIn: NSRange(currentText.endIndex..<currentText.endIndex, in: currentText),
            replacementString: "1")
        
        XCTAssertFalse(result!)
        XCTAssertEqual(expiryDate?.actualValue, "23/1")
        XCTAssertEqual(expiryDate?.textField.secureText, "23/1")
    }
    
    func testExpiryDateFormattingBackspace() {
        let expiryDate = getexpiryDateElement()

        let currentText = "23/1"
        expiryDate?.textField.secureText = currentText
        let lastIndex = currentText.index(before: currentText.endIndex)
        let result = expiryDate?.textField.delegate?.textField?(
            expiryDate!.textField,
            shouldChangeCharactersIn: NSRange(lastIndex..<currentText.endIndex, in: currentText),
            replacementString: "")
        
        
        XCTAssertFalse(result!)
        XCTAssertEqual(expiryDate?.actualValue, "23")
        XCTAssertEqual(expiryDate?.textField.secureText, "23")
    }
    
    func testExpiryMonthFormattingSingleDigit() {
        let expiryMonth = getExpiryMonthElement()
        let currentText = ""
        
        expiryMonth?.textField.secureText = currentText
        
        let result = expiryMonth?.textField.delegate?.textField?(
            expiryMonth!.textField,
            shouldChangeCharactersIn: NSRange(currentText.endIndex..<currentText.endIndex, in: currentText),
            replacementString: "6")
        
        XCTAssertFalse(result!)
        XCTAssertEqual(expiryMonth?.actualValue, "06")
        XCTAssertEqual(expiryMonth?.textField.secureText, "06")
    }
    
    func testExpiryMonthFormattingDoubleDigitValid() {
        let expiryMonth = getExpiryMonthElement()
        let currentText = "01"
        
        expiryMonth?.textField.secureText = currentText
        
        let result = expiryMonth?.textField.delegate?.textField?(
            expiryMonth!.textField,
            shouldChangeCharactersIn: NSRange(currentText.endIndex..<currentText.endIndex, in: currentText),
            replacementString: "2")
        
        XCTAssertFalse(result!)
        XCTAssertEqual(expiryMonth?.actualValue, "12")
        XCTAssertEqual(expiryMonth?.textField.secureText, "12")
    }
    
    func testExpiryMonthFormattingDoubleDigitInvalid() {
        let expiryMonth = getExpiryMonthElement()
        let currentText = "01"
        
        expiryMonth?.textField.secureText = currentText
        
        let result = expiryMonth?.textField.delegate?.textField?(
            expiryMonth!.textField,
            shouldChangeCharactersIn: NSRange(currentText.endIndex..<currentText.endIndex, in: currentText),
            replacementString: "6")
        
        XCTAssertFalse(result!)
        XCTAssertEqual(expiryMonth?.actualValue, "01")
        XCTAssertEqual(expiryMonth?.textField.secureText, "01")
    }
    
    func testExpiryMonthFormattingBackspaceSingleDigit() {
        let expiryMonth = getExpiryMonthElement()
        let currentText = "01"
        
        expiryMonth?.textField.secureText = currentText
        let lastIndex = currentText.index(before: currentText.endIndex)
        
        let result = expiryMonth?.textField.delegate?.textField?(
            expiryMonth!.textField,
            shouldChangeCharactersIn: NSRange(lastIndex..<currentText.endIndex, in: currentText),
            replacementString: "")
        
        XCTAssertFalse(result!)
        XCTAssertEqual(expiryMonth?.actualValue, "")
        XCTAssertEqual(expiryMonth?.textField.secureText, "")
    }
    
    func testExpiryMonthFormattingBackspaceDoubleDigit() {
        let expiryMonth = getExpiryMonthElement()
        let currentText = "12"
        
        expiryMonth?.textField.secureText = currentText
        let lastIndex = currentText.index(before: currentText.endIndex)
        
        let result = expiryMonth?.textField.delegate?.textField?(
            expiryMonth!.textField,
            shouldChangeCharactersIn: NSRange(lastIndex..<currentText.endIndex, in: currentText),
            replacementString: "")
        
        XCTAssertFalse(result!)
        XCTAssertEqual(expiryMonth?.textField.secureText, "1")
        XCTAssertEqual(expiryMonth?.actualValue, "1")
        
        expiryMonth?.textField.delegate?.textFieldDidEndEditing!(expiryMonth!.textField)
        XCTAssertEqual(expiryMonth?.textField.secureText, "01")
    }
    
    func testCardBin() {
        XCTAssertEqual(Card.getBIN("4111 1111 "), "4111 1111 ")
        XCTAssertEqual(Card.getBIN("4111 1111 1111 111"), "4111 1111 XXXX XXX")
        XCTAssertEqual(Card.getBIN("411"), "411")
    }
    
    func testStateWithBIN() {
        let prodOptions = ContextOptions()
        let devOptions = ContextOptions(env: .DEV)
        let cardInput = CollectElementInput(type: .CARD_NUMBER)
        
        let prodField = TextField(input: cardInput, options: CollectElementOptions(), contextOptions: prodOptions)
        let devField = TextField(input: cardInput, options: CollectElementOptions(), contextOptions: devOptions)
        
        prodField.actualValue = "4111 1111 1111 1111"
        devField.actualValue = "4111 1111 1111 1111"
        
        XCTAssertEqual((prodField.state as! StateforText).getStateForListener()["value"] as? String, "4111 1111 XXXX XXXX")
        XCTAssertEqual((devField.state as! StateforText).getStateForListener()["value"] as? String, "4111 1111 1111 1111")
    }
    
    func testStateWithoutBIN() {
        let cvvInput = CollectElementInput(type: .CVV)
        let expirationDateInput = CollectElementInput(type: .EXPIRATION_DATE)
        let expirationYearInput = CollectElementInput(type: .EXPIRATION_YEAR)
        let expirationMonthInput = CollectElementInput(type: .EXPIRATION_MONTH)
        let nameInput = CollectElementInput(type: .CARDHOLDER_NAME)
        let genericInput = CollectElementInput(type: .INPUT_FIELD)
        let pinInput = CollectElementInput(type: .PIN)

        let prodOptions = ContextOptions()
        let devOptions = ContextOptions(env: .DEV)
        
        // cvv
        var prodField = TextField(input: cvvInput, options: CollectElementOptions(), contextOptions: prodOptions)
        var devField = TextField(input: cvvInput, options: CollectElementOptions(), contextOptions: devOptions)
        
        prodField.actualValue = "572"
        devField.actualValue = "572"
        
        XCTAssertEqual((prodField.state as! StateforText).getStateForListener()["value"] as! String, "")
        XCTAssertEqual((devField.state as! StateforText).getStateForListener()["value"] as? String, "572")
        
        // expiryDate
        prodField = TextField(input: expirationDateInput, options: CollectElementOptions(), contextOptions: prodOptions)
        devField = TextField(input: expirationDateInput, options: CollectElementOptions(), contextOptions: devOptions)
        
        prodField.actualValue = "12/24"
        devField.actualValue = "12/24"
        
        XCTAssertEqual((prodField.state as! StateforText).getStateForListener()["value"] as! String, "")
        XCTAssertEqual((devField.state as! StateforText).getStateForListener()["value"] as? String, "12/24")
        
        // expiryYear
        prodField = TextField(input: expirationYearInput, options: CollectElementOptions(), contextOptions: prodOptions)
        devField = TextField(input: expirationYearInput, options: CollectElementOptions(), contextOptions: devOptions)
        
        prodField.actualValue = "2024"
        devField.actualValue = "2024"
        
        XCTAssertEqual((prodField.state as! StateforText).getStateForListener()["value"] as! String, "")
        XCTAssertEqual((devField.state as! StateforText).getStateForListener()["value"] as? String, "2024")
        
        // expiryMonth
        prodField = TextField(input: expirationMonthInput, options: CollectElementOptions(), contextOptions: prodOptions)
        devField = TextField(input: expirationDateInput, options: CollectElementOptions(), contextOptions: devOptions)
        
        prodField.actualValue = "12"
        devField.actualValue = "12"
        
        XCTAssertEqual((prodField.state as! StateforText).getStateForListener()["value"] as! String, "")
        XCTAssertEqual((devField.state as! StateforText).getStateForListener()["value"] as? String, "12")
        
        // cardholderName
        prodField = TextField(input: nameInput, options: CollectElementOptions(), contextOptions: prodOptions)
        devField = TextField(input: nameInput, options: CollectElementOptions(), contextOptions: devOptions)
        
        prodField.actualValue = "John"
        devField.actualValue = "John"
        
        XCTAssertEqual((prodField.state as! StateforText).getStateForListener()["value"] as! String, "")
        XCTAssertEqual((devField.state as! StateforText).getStateForListener()["value"] as? String, "John")
        
        // PIN
        prodField = TextField(input: expirationDateInput, options: CollectElementOptions(), contextOptions: prodOptions)
        devField = TextField(input: expirationDateInput, options: CollectElementOptions(), contextOptions: devOptions)
        
        prodField.actualValue = "1234"
        devField.actualValue = "1234"
        
        XCTAssertEqual((prodField.state as! StateforText).getStateForListener()["value"] as! String, "")
        XCTAssertEqual((devField.state as! StateforText).getStateForListener()["value"] as? String, "1234")
        
        // generic
        prodField = TextField(input: expirationDateInput, options: CollectElementOptions(), contextOptions: prodOptions)
        devField = TextField(input: expirationDateInput, options: CollectElementOptions(), contextOptions: devOptions)
        
        prodField.actualValue = "1234"
        devField.actualValue = "1234"
        
        XCTAssertEqual((prodField.state as! StateforText).getStateForListener()["value"] as! String, "")
        XCTAssertEqual((devField.state as! StateforText).getStateForListener()["value"] as? String, "1234")

    }
    
    testStateForAmex() {
        let amexInput = CollectElementInput(type: .CARD_NUMBER)

        let prodOptions = ContextOptions()
        let devOptions = ContextOptions(env: .DEV)
        
        var prodField = TextField(input: amexInput, options: CollectElementOptions(), contextOptions: prodOptions)
        var devField = TextField(input: amexInput, options: CollectElementOptions(), contextOptions: devOptions)
        
        prodField.actualValue = "378282246310005"
        devField.actualValue = "378282246310005"
        
        XCTAssertEqual((prodField.state as! StateforText).getStateForListener()["value"] as! String, "")
        XCTAssertEqual((devField.state as! StateforText).getStateForListener()["value"] as? String, "37828XXXXXXXXXX")
    }

}
