import XCTest
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
        XCTAssertEqual(expiryMonth?.textField.secureText, "01")
        XCTAssertEqual(expiryMonth?.actualValue, "01")
    }

}
