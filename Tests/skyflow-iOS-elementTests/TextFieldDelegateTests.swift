//
//  TextFieldDelegateTests.swift
//  
//
//  Created by Bharti Sagar on 17/04/23.
//

import XCTest
import Foundation
@testable import Skyflow

// swiftlint:disable:next type_body_length

class TextFieldDelegateTests: XCTestCase {
    var skyflow: Client!

    override func setUp() {
        self.skyflow = Skyflow.initialize(
            Configuration(vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!,
                          vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!,
                          tokenProvider: DemoTokenProvider())
        )
    }

    func getInputFieldElement() -> TextField?{
        
        let window = UIWindow()
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let collectOptions = CollectElementOptions(required: false, format: "+91 YYYY-YYYY-YYYY YYYY XXXX", translation: ["X": "[A-Z]", "Y": "[0-9]", "Z": "[A-Za-z0-9]"])

        let inputFieldInput = CollectElementInput(table: "persons", column: "input_field", placeholder: "input_field", type: .INPUT_FIELD)
        
        let inputField = container?.create(input: inputFieldInput, options: collectOptions)
        window.addSubview(inputField!)
        
        return inputField
    }
    func getInputFieldElementWithNoTranslation() -> TextField?{
        
        let window = UIWindow()
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let collectOptions = CollectElementOptions(required: false, format: "+91 YYYY-YYYY-YYYY YYYY XXXX")

        let inputFieldInput = CollectElementInput(table: "persons", column: "input_field", placeholder: "input_field", type: .INPUT_FIELD)
        
        let inputField = container?.create(input: inputFieldInput, options: collectOptions)
        window.addSubview(inputField!)
        
        return inputField
    }
    func getInputFieldElementPhoneNumber() -> TextField?{
        
        let window = UIWindow()
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let collectOptions = CollectElementOptions(required: false, format: "+91 XX XXXX XXXX", translation: ["X": "[0-9]"])

        let inputFieldInput = CollectElementInput(table: "persons", column: "input_field", placeholder: "phone Number", type: .INPUT_FIELD)
        
        let inputField = container?.create(input: inputFieldInput, options: collectOptions)
        window.addSubview(inputField!)
        
        return inputField
    }
    func getInputFieldElementPhoneNumberCase2() -> TextField?{
        
        let window = UIWindow()
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let collectOptions = CollectElementOptions(required: false, format: "(XXX) XXX-XXXX", translation: ["X": "[0-9]"])

        let inputFieldInput = CollectElementInput(table: "persons", column: "input_field", placeholder: "phone Number", type: .INPUT_FIELD)
        
        let inputField = container?.create(input: inputFieldInput, options: collectOptions)
        window.addSubview(inputField!)
        
        return inputField
    }
    func getInputFieldElementSSN() -> TextField?{
        
        let window = UIWindow()
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let collectOptions = CollectElementOptions(required: false, format: "XXX-XX-XXXX", translation: ["X": "[0-9]"])

        let inputFieldInput = CollectElementInput(table: "persons", column: "input_field", placeholder: "phone Number", type: .INPUT_FIELD)
        
        let inputField = container?.create(input: inputFieldInput, options: collectOptions)
        window.addSubview(inputField!)
        
        return inputField
    }
    func getInputFieldElementPassportNumber() -> TextField?{
        
        let window = UIWindow()
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let collectOptions = CollectElementOptions(required: false, format: "X-YYYYYYY", translation: ["X": "[A-Z]", "Y": "[0-9]"])

        let inputFieldInput = CollectElementInput(table: "persons", column: "input_field", placeholder: "phone Number", type: .INPUT_FIELD)
        
        let inputField = container?.create(input: inputFieldInput, options: collectOptions)
        window.addSubview(inputField!)
        
        return inputField
    }

    func testForformatInput(){
        let InputFieldElement = getInputFieldElement()
        let result = InputFieldElement?.textField.delegate?.textField?(
            InputFieldElement!.textField,
            shouldChangeCharactersIn: NSRange(location: 0,length: 0),
            replacementString: "1")
        XCTAssertFalse(result!)
        XCTAssertEqual(InputFieldElement?.actualValue, "+91 1")
        XCTAssertEqual(InputFieldElement?.textField.secureText, "+91 1")
    }
    func testForformatInputDefaultTranslation(){
        let InputFieldElement = getInputFieldElementWithNoTranslation()
        let result = InputFieldElement?.textField.delegate?.textField?(
            InputFieldElement!.textField,
            shouldChangeCharactersIn: NSRange(location: 0,length: 0),
            replacementString: "1234")
        XCTAssertFalse(result!)
        XCTAssertEqual(InputFieldElement?.actualValue, "+91 YYYY-YYYY-YYYY YYYY 1234")
        XCTAssertEqual(InputFieldElement?.textField.secureText, "+91 YYYY-YYYY-YYYY YYYY 1234")
    }
    func testForformatInputPhoneNumber(){
        let InputFieldElement = getInputFieldElementPhoneNumber()
        let result = InputFieldElement?.textField.delegate?.textField?(
            InputFieldElement!.textField,
            shouldChangeCharactersIn: NSRange(location: 0,length: 0),
            replacementString: "1234567890")
        XCTAssertFalse(result!)
        XCTAssertEqual(InputFieldElement?.actualValue, "+91 12 3456 7890")
        XCTAssertEqual(InputFieldElement?.textField.secureText, "+91 12 3456 7890")
    }
    func testForformatInputPhoneNumberCase2(){
        let InputFieldElement = getInputFieldElementPhoneNumberCase2()
        let result = InputFieldElement?.textField.delegate?.textField?(
            InputFieldElement!.textField,
            shouldChangeCharactersIn: NSRange(location: 0,length: 0),
            replacementString: "1234567890")
        XCTAssertFalse(result!)
        XCTAssertEqual(InputFieldElement?.actualValue, "(123) 456-7890")
        XCTAssertEqual(InputFieldElement?.textField.secureText, "(123) 456-7890")
    }
    func testForformatInputSSN(){
        let InputFieldElement = getInputFieldElementSSN()
        let result = InputFieldElement?.textField.delegate?.textField?(
            InputFieldElement!.textField,
            shouldChangeCharactersIn: NSRange(location: 0,length: 0),
            replacementString: "123456789")
        XCTAssertFalse(result!)
        XCTAssertEqual(InputFieldElement?.actualValue, "123-45-6789")
        XCTAssertEqual(InputFieldElement?.textField.secureText, "123-45-6789")
    }
    func testForformatInputPassportNumber(){
        let InputFieldElement = getInputFieldElementPassportNumber()
        let result = InputFieldElement?.textField.delegate?.textField?(
            InputFieldElement!.textField,
            shouldChangeCharactersIn: NSRange(location: 0,length: 0),
            replacementString: "A1234567")
        XCTAssertFalse(result!)
        XCTAssertEqual(InputFieldElement?.actualValue, "A-1234567")
        XCTAssertEqual(InputFieldElement?.textField.secureText, "A-1234567")
    }
    func testForformatInput2(){
        let InputFieldElement = getInputFieldElementPassportNumber()
        let result = InputFieldElement?.textField.delegate?.textField?(
            InputFieldElement!.textField,
            shouldChangeCharactersIn: NSRange(location: 0,length: 0),
            replacementString: "A1234567")
        XCTAssertFalse(result!)
        XCTAssertEqual(InputFieldElement?.actualValue, "A-1234567")
        XCTAssertEqual(InputFieldElement?.textField.secureText, "A-1234567")
    }
}
