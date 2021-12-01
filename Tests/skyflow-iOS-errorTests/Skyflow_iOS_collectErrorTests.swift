//
//  Skyflow_iOS_collectErrorTests.swift
//  skyflow-iOS-collectTests
//
//  Created by Tejesh Reddy Allampati on 07/10/21.
//

import XCTest

import XCTest
@testable import Skyflow

// swiftlint:disable:next type_body_length
final class Skyflow_iOS_collectErrorTests: XCTestCase {
    var skyflow: Client!
    var records: [[String: Any]]!
    var firstFields: [String: Any]!
    var secondFields: [String: Any]!
    
    override func setUp() {
        self.skyflow = Client(
            Configuration(vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!,
                          vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!,
                          tokenProvider: DemoTokenProvider())
        )
        self.firstFields = ["cvv": "123",
                            "cardExpiration": "1221",
                            "cardNumber": "1232132132311231",
                            "name": ["first_name": "Bob"]
        ]
        self.secondFields = [
            "cvv": "123",
            "cardExpiration": "1221",
            "cardNumber": "1232132132311231",
            "name": ["first_name": "Bobb"]
        ]
        self.records = [
            ["table": "persons",
             "fields": firstFields as Any
            ],
            ["table": "persons",
             "fields": secondFields as Any
            ]
        ]
    }
    
    override func tearDown() {
        skyflow = nil
    }
    
    func testNoRecordsKeyInPayload() {
        let payload: [String: Any] = [
            "typo": records
        ]
        
        let expectation = XCTestExpectation(description: "Pure insert call")
        
        let callback = DemoAPICallback(expectation: expectation)
        skyflow.insert(records: payload, options: InsertOptions(tokens: true), callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        let responseData = callback.receivedResponse.utf8
        
        XCTAssertEqual(String(responseData), "Interface: client insert - " + ErrorCodes.RECORDS_KEY_ERROR().description)
    }
    
    func testInvalidRecordsKeyInPayload() {
        let payload: [String: Any] = ["records": 12]
        
        let expectation = XCTestExpectation(description: "Pure insert call")
        
        let callback = DemoAPICallback(expectation: expectation)
        skyflow.insert(records: payload, options: InsertOptions(tokens: true), callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        let responseData = callback.receivedResponse.utf8
        XCTAssertEqual(String(responseData), "Interface: client insert - " + ErrorCodes.INVALID_RECORDS_TYPE().description)
    }
    
    func testNoTableKeyInPayload() {
        let payload = [
            "records": [
                [
                    "fields": firstFields
                ]
            ]
        ]
        let expectation = XCTestExpectation(description: "Pure insert call")
        
        let callback = DemoAPICallback(expectation: expectation)
        skyflow.insert(records: payload, options: InsertOptions(tokens: true), callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        let responseData = callback.receivedResponse.utf8
        
        XCTAssertEqual(String(responseData), "Interface: client insert - " + ErrorCodes.TABLE_KEY_ERROR().description)
    }
    
    func testInvalidTableNameType() {
        let payload = [
            "records": [
                [
                    "table": 123,
                    "fields": firstFields
                ]
            ]
        ]
        let expectation = XCTestExpectation(description: "Pure insert call")
        
        let callback = DemoAPICallback(expectation: expectation)
        skyflow.insert(records: payload, options: InsertOptions(tokens: true), callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        let responseData = callback.receivedResponse.utf8
        
        XCTAssertEqual(String(responseData), "Interface: client insert - " + ErrorCodes.INVALID_TABLE_NAME_TYPE().description)
    }
    
    func testNoFieldsKeyInPayload() {
        let payload = [
            "records": [
                [
                    "table": "sometable"
                ]
            ]
        ]
        let expectation = XCTestExpectation(description: "Pure insert call")
        
        let callback = DemoAPICallback(expectation: expectation)
        skyflow.insert(records: payload, options: InsertOptions(tokens: true), callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        let responseData = callback.receivedResponse.utf8
        
        XCTAssertEqual(String(responseData), "Interface: client insert - " + ErrorCodes.FIELDS_KEY_ERROR().description)
    }
    
    func testInvalidFieldsType() {
        let payload = [
            "records": [
                [
                    "table": "sometable",
                    "fields": "firstFields"
                ]
            ]
        ]
        let expectation = XCTestExpectation(description: "Pure insert call")
        
        let callback = DemoAPICallback(expectation: expectation)
        skyflow.insert(records: payload, options: InsertOptions(tokens: true), callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        let responseData = callback.receivedResponse.utf8
        
        XCTAssertEqual(String(responseData), "Interface: client insert - " + ErrorCodes.INVALID_FIELDS_TYPE().description)
    }
    
    func testContainerNoTableName() {
        let window = UIWindow()
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput1 = CollectElementInput(placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput1, options: options)
        
        cardNumber?.textField.secureText = "4111 1111 1111 1111"
        
        window.addSubview(cardNumber!)
        
        let collectInput2 = CollectElementInput(table: "persons", column: "cvv", placeholder: "cvv", type: .CVV)
        
        let cvv = container?.create(input: collectInput2, options: options)
        
        cvv?.textField.secureText = "211"
        window.addSubview(cvv!)
        
        let expectation = XCTestExpectation(description: "Container insert call - All valid")
        
        let callback = DemoAPICallback(expectation: expectation)
        
        container?.collect(callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        
        let responseData = callback.receivedResponse
        XCTAssertEqual(responseData, "Interface: collect container - " + ErrorCodes.EMPTY_TABLE_NAME().description)
        
    }
    
    func testEmptyColumnName() {
        let window = UIWindow()
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput1 = CollectElementInput(table: "persons", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput1, options: options)
        
        cardNumber?.textField.secureText = "4111 1111 1111 1111"
        
        window.addSubview(cardNumber!)
        
        let collectInput2 = CollectElementInput(table: "persons", column: "cvv", placeholder: "cvv", type: .CVV)
        
        let cvv = container?.create(input: collectInput2, options: options)
        
        cvv?.textField.secureText = "211"
        window.addSubview(cvv!)
        
        let expectation = XCTestExpectation(description: "Container insert call - All valid")
        
        let callback = DemoAPICallback(expectation: expectation)
        
        container?.collect(callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        
        let responseData = callback.receivedResponse
        XCTAssertEqual(responseData, "Interface: collect container - " + ErrorCodes.EMPTY_COLUMN_NAME().description)
        
    }
    
    func testUnmountedElements() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput1 = CollectElementInput(table: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput1, options: options)
        
        cardNumber?.textField.secureText = "4111 1111 1111 1111"
        
        
        let expectation = XCTestExpectation(description: "Container insert call - Unmounted")
        
        let callback = DemoAPICallback(expectation: expectation)
        
        container?.collect(callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        
        let responseData = callback.receivedResponse
        XCTAssertEqual(responseData, "Interface: collect container - " + ErrorCodes.UNMOUNTED_COLLECT_ELEMENT(value: "card_number").description)
    }
    
    func testCreateRequestBodyDuplicateElements() {
        let window = UIWindow()
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let options = CollectElementOptions(required: false)
        let collectInput1 = CollectElementInput(table: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
        let cardNumber = container?.create(input: collectInput1, options: options)
        cardNumber?.textField.secureText = "4111 1111 1111 1111"
        window.addSubview(cardNumber!)
        
        let collectInput2 = CollectElementInput(table: "persons", column: "card_number", placeholder: "cvv", type: .CVV)
        let cvv = container?.create(input: collectInput2, options: options)
        cvv?.textField.secureText = "211"
        window.addSubview(cvv!)
        let expectation = XCTestExpectation(description: "Container insert call - Duplicate Elements")
        let callback = DemoAPICallback(expectation: expectation)
        CollectRequestBody.createRequestBody(elements: [cardNumber!, cvv!], callback: callback, contextOptions: ContextOptions(interface: .COLLECT_CONTAINER))
        wait(for: [expectation], timeout: 10.0)
        
        let responseData = callback.receivedResponse
        XCTAssertEqual(responseData, "Interface: collect container - " + ErrorCodes.DUPLICATE_ELEMENT_FOUND(values: ["persons", "card_number"]).description)
    }
    
    func testCreateRequestBodyDuplicatedAdditionalField() {
        let window = UIWindow()
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let options = CollectElementOptions(required: false)
        let collectInput1 = CollectElementInput(table: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
        let cardNumber = container?.create(input: collectInput1, options: options)
        cardNumber?.textField.secureText = "4111 1111 1111 1111"
        window.addSubview(cardNumber!)
        
        let collectInput2 = CollectElementInput(table: "persons", column: "cvv", placeholder: "cvv", type: .CVV)
        let cvv = container?.create(input: collectInput2, options: options)
        cvv?.textField.secureText = "211"
        window.addSubview(cvv!)
        let expectation = XCTestExpectation(description: "Container insert call - All valid")
        let callback = DemoAPICallback(expectation: expectation)
        
        let fields: [String: Any] = [
            "records": [[
                            "table": "persons",
                            "fields": [
                                "cvv": "123",
                                "name": "John Doe"
                            ]]
            ]]
        CollectRequestBody.createRequestBody(elements: [cardNumber!, cvv!], additionalFields: fields,callback: callback, contextOptions: ContextOptions(interface: .COLLECT_CONTAINER))
        wait(for: [expectation], timeout: 10.0)
        
        let responseData = callback.receivedResponse
        XCTAssertEqual(responseData, "Interface: collect container - " + ErrorCodes.DUPLICATE_ELEMENT_FOUND(values: ["persons", "cvv"]).description)
    }
    
    func testCreateRequestBodyDuplicateInAdditionalFields() {
        let window = UIWindow()
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let options = CollectElementOptions(required: false)
        let collectInput1 = CollectElementInput(table: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
        let cardNumber = container?.create(input: collectInput1, options: options)
        cardNumber?.textField.secureText = "4111 1111 1111 1111"
        window.addSubview(cardNumber!)
        
        let collectInput2 = CollectElementInput(table: "persons", column: "cvv", placeholder: "cvv", type: .CVV)
        let cvv = container?.create(input: collectInput2, options: options)
        cvv?.textField.secureText = "211"
        window.addSubview(cvv!)
        let expectation = XCTestExpectation(description: "Container insert call - All valid")
        let callback = DemoAPICallback(expectation: expectation)
        
        let fields: [String: Any] = [
            "records": [[
                            "table": "persons",
                            "fields": [
                                "duplicate": "123",
                                "name": "John Doe"
                            ]],
                        [
                            "table": "persons",
                            "fields": [
                                "duplicate": "123",
                            ]]
            ]]
        CollectRequestBody.createRequestBody(elements: [cardNumber!, cvv!], additionalFields: fields,callback: callback, contextOptions: ContextOptions(interface: .COLLECT_CONTAINER))
        wait(for: [expectation], timeout: 10.0)
        
        let responseData = callback.receivedResponse
        XCTAssertEqual(responseData, "Interface: collect container - " + ErrorCodes.DUPLICATE_ADDITIONAL_FIELD_FOUND(values: ["persons", "duplicate"]).description)
    }
    
}
