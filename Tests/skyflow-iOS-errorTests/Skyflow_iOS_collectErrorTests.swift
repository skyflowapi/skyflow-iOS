/*
 * Copyright (c) 2022 Skyflow
*/

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
            Configuration(vaultID: "id",
                          vaultURL: "http://demo.com",
                          tokenProvider: DemoTokenProvider(), options: Options(logLevel: .DEBUG))
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
        
        XCTAssertEqual(String(responseData), ErrorCodes.RECORDS_KEY_ERROR().description)
    }
    
    func testInvalidRecordsKeyInPayload() {
        let payload: [String: Any] = ["records": 12]
        
        let expectation = XCTestExpectation(description: "Pure insert call")
        
        let callback = DemoAPICallback(expectation: expectation)
        skyflow.insert(records: payload, options: InsertOptions(tokens: true), callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        let responseData = callback.receivedResponse.utf8
        XCTAssertEqual(String(responseData), ErrorCodes.INVALID_RECORDS_TYPE().description)
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
        
        XCTAssertEqual(String(responseData), ErrorCodes.TABLE_KEY_ERROR(value: "\(0)").description)
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
        
        XCTAssertEqual(String(responseData),  ErrorCodes.INVALID_TABLE_NAME_TYPE(value: "\(0)").description)
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
        
        XCTAssertEqual(String(responseData),  ErrorCodes.FIELDS_KEY_ERROR(value: "\(0)").description)
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
        
        XCTAssertEqual(String(responseData),  ErrorCodes.INVALID_FIELDS_TYPE(value: "\(0)").description)
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
        
        container?.collect(callback: callback.asCollectCallback)
        
        wait(for: [expectation], timeout: 10.0)
        
        let responseData = callback.receivedResponse
        XCTAssertEqual(responseData,  ErrorCodes.EMPTY_TABLE_NAME_IN_COLLECT().description)
        
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
        
        container?.collect(callback: callback.asCollectCallback)
        
        wait(for: [expectation], timeout: 10.0)
        
        let responseData = callback.receivedResponse
        XCTAssertEqual(responseData,  ErrorCodes.EMPTY_COLUMN_NAME_IN_COLLECT().description)
        
    }
    
    func testUnmountedElements() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput1 = CollectElementInput(table: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput1, options: options)
        
        cardNumber?.textField.secureText = "4111 1111 1111 1111"
        
        
        let expectation = XCTestExpectation(description: "Container insert call - Unmounted")
        
        let callback = DemoAPICallback(expectation: expectation)
        
        container?.collect(callback: callback.asCollectCallback)
        
        wait(for: [expectation], timeout: 10.0)
        
        let responseData = callback.receivedResponse
        XCTAssertEqual(responseData,  ErrorCodes.UNMOUNTED_COLLECT_ELEMENT(value: "card_number").description)
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
        FlowVaultCollectRequestBody.createRequestBody(elements: [cardNumber!, cvv!], callback: callback, contextOptions: ContextOptions(interface: .COLLECT_CONTAINER))
        wait(for: [expectation], timeout: 10.0)
        
        let responseData = callback.receivedResponse
        XCTAssertEqual(responseData,  ErrorCodes.DUPLICATE_ELEMENT_FOUND(values: ["card_number", "persons"]).description)
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
        FlowVaultCollectRequestBody.createRequestBody(elements: [cardNumber!, cvv!], additionalFields: fields,callback: callback, contextOptions: ContextOptions(interface: .COLLECT_CONTAINER))
        wait(for: [expectation], timeout: 10.0)
        
        let responseData = callback.receivedResponse
        XCTAssertEqual(responseData,  ErrorCodes.DUPLICATE_ELEMENT_FOUND(values: ["cvv", "persons"]).description)
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
        FlowVaultCollectRequestBody.createRequestBody(elements: [cardNumber!, cvv!], additionalFields: fields,callback: callback, contextOptions: ContextOptions(interface: .COLLECT_CONTAINER))
        wait(for: [expectation], timeout: 10.0)
        
        let responseData = callback.receivedResponse
        XCTAssertEqual(responseData,  ErrorCodes.DUPLICATE_ADDITIONAL_FIELD_FOUND(value: "duplicate").description)
    }
    func testCreateRequestInsertBodyDuplicateInAdditionalFields() {
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
                            ]],
                        [
                            "table": "persons",
                            "fields": [
                                "duplicate": "123",
                            ]]
            ]]
        FlowVaultCollectRequestBody.createRequestBody(elements: [cardNumber!, cvv!], additionalFields: fields,callback: callback, contextOptions: ContextOptions(interface: .COLLECT_CONTAINER))
        wait(for: [expectation], timeout: 10.0)
        
        let responseData = callback.receivedResponse
        XCTAssertEqual(responseData,  ErrorCodes.DUPLICATE_ELEMENT_FOUND(values: ["cvv", "persons"]).description)
    }
    
    func testCreateRequestBodyWithOnlyInserts() {
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
        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Insert only"))
        let requestBody = FlowVaultCollectRequestBody.createRequestBody(elements: [cardNumber!, cvv!], callback: callback, contextOptions: ContextOptions())
        XCTAssertNotNil(requestBody)
        XCTAssertNotNil(requestBody?["records"])
        XCTAssertEqual(requestBody?["records"] as! [NSDictionary], [
            ["table": "persons", "fields": ["card_number": "", "cvv": ""]]
        ])
    }

    func testCreateRequestBodyWithSkyflowIDInAdditionalFields() {
        let additionalFields: [String: Any] = [
            "records": [
                ["table": "table1", "fields": ["column1": "value1"], "skyflowID": "id1"]
            ]
        ]
        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Update via additionalFields"))
        let requestBody = FlowVaultCollectRequestBody.createRequestBody(elements: [], additionalFields: additionalFields, callback: callback, contextOptions: ContextOptions())
        XCTAssertNotNil(requestBody)
        XCTAssertEqual((requestBody?["records"] as! [[String: Any]]).count, 0)
        let update = requestBody?["update"] as! [String: Any]
        let entry = update["id1"] as! [String: Any]
        XCTAssertEqual(entry["table"] as! String, "table1")
        XCTAssertEqual(entry["fields"] as! [String: String], ["column1": "value1"])
    }

    func testCreateRequestBodyWithSkyflowIDOnElement() {
        let window = UIWindow()
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let options = CollectElementOptions(required: false)
        let collectInput1 = CollectElementInput(table: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER, skyflowID: "id1")
        let cardNumber = container?.create(input: collectInput1, options: options)
        cardNumber?.textField.secureText = "4111 1111 1111 1111"
        window.addSubview(cardNumber!)

        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Update via element skyflowID"))
        let requestBody = FlowVaultCollectRequestBody.createRequestBody(elements: [cardNumber!], callback: callback, contextOptions: ContextOptions())
        XCTAssertNotNil(requestBody)
        XCTAssertEqual((requestBody?["records"] as! [[String: Any]]).count, 0)
        let update = requestBody?["update"] as! [String: Any]
        let entry = update["id1"] as! [String: Any]
        XCTAssertEqual(entry["table"] as! String, "persons")
        XCTAssertEqual(entry["fields"] as! [String: String], ["card_number": ""])
    }

    func testInsertEmptyVaultURL() {
        let expectation = XCTestExpectation(description: "Insert with empty vaultURL should fail")
        let callback = DemoAPICallback(expectation: expectation)
        let clientWithEmptyURL = Client(Configuration(vaultID: "id", vaultURL: "", tokenProvider: DemoTokenProvider()))

        clientWithEmptyURL.insert(records: ["records": [["table": "table", "fields": ["field": "value"]]]], callback: callback)

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.EMPTY_VAULT_URL().getErrorObject(contextOptions: ContextOptions(interface: .INSERT)).localizedDescription)
    }

}
