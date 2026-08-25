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
@testable import SkyflowFlowVault
@testable import SkyflowCore

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
    
    func testContainerNoTableName() {
        let window = UIWindow()
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput1 = CollectElementInput(placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput1, options: options)
        
        cardNumber?.textField.secureText = "4111 1111 1111 1111"
        
        window.addSubview(cardNumber!)
        
        let collectInput2 = CollectElementInput(tableName: "persons", column: "cvv", placeholder: "cvv", type: .CVV)
        
        let cvv = container?.create(input: collectInput2, options: options)
        
        cvv?.textField.secureText = "211"
        window.addSubview(cvv!)
        
        let expectation = XCTestExpectation(description: "Container insert call - All valid")
        
        let callback = DemoAPICallback(expectation: expectation)
        
        container?.collect(callback: callback.asCollectCallback)
        
        wait(for: [expectation], timeout: 10.0)
        
        let responseData = callback.receivedResponse
        XCTAssertEqual(responseData,  ErrorCodes.EMPTY_TABLE_NAME_IN_COLLECT().describedFor(productName: "SkyflowFlowVault"))
        
    }
    
    func testEmptyColumnName() {
        let window = UIWindow()
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput1 = CollectElementInput(tableName: "persons", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput1, options: options)
        
        cardNumber?.textField.secureText = "4111 1111 1111 1111"
        
        window.addSubview(cardNumber!)
        
        let collectInput2 = CollectElementInput(tableName: "persons", column: "cvv", placeholder: "cvv", type: .CVV)
        
        let cvv = container?.create(input: collectInput2, options: options)
        
        cvv?.textField.secureText = "211"
        window.addSubview(cvv!)
        
        let expectation = XCTestExpectation(description: "Container insert call - All valid")
        
        let callback = DemoAPICallback(expectation: expectation)
        
        container?.collect(callback: callback.asCollectCallback)
        
        wait(for: [expectation], timeout: 10.0)
        
        let responseData = callback.receivedResponse
        XCTAssertEqual(responseData,  ErrorCodes.EMPTY_COLUMN_NAME_IN_COLLECT().describedFor(productName: "SkyflowFlowVault"))
        
    }
    
    func testUnmountedElements() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput1 = CollectElementInput(tableName: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput1, options: options)
        
        cardNumber?.textField.secureText = "4111 1111 1111 1111"
        
        
        let expectation = XCTestExpectation(description: "Container insert call - Unmounted")
        
        let callback = DemoAPICallback(expectation: expectation)
        
        container?.collect(callback: callback.asCollectCallback)
        
        wait(for: [expectation], timeout: 10.0)
        
        let responseData = callback.receivedResponse
        XCTAssertEqual(responseData,  ErrorCodes.UNMOUNTED_COLLECT_ELEMENT(value: "card_number").describedFor(productName: "SkyflowFlowVault"))
    }
    
    func testCreateRequestBodyDuplicateElements() {
        let window = UIWindow()
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let options = CollectElementOptions(required: false)
        let collectInput1 = CollectElementInput(tableName: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
        let cardNumber = container?.create(input: collectInput1, options: options)
        cardNumber?.textField.secureText = "4111 1111 1111 1111"
        window.addSubview(cardNumber!)
        
        let collectInput2 = CollectElementInput(tableName: "persons", column: "card_number", placeholder: "cvv", type: .CVV)
        let cvv = container?.create(input: collectInput2, options: options)
        cvv?.textField.secureText = "211"
        window.addSubview(cvv!)
        let expectation = XCTestExpectation(description: "Container insert call - Duplicate Elements")
        let callback = DemoAPICallback(expectation: expectation)
        CollectRequestBuilder.createCollectRecords(elements: [cardNumber!, cvv!], callback: callback, contextOptions: ContextOptions(interface: .COLLECT_CONTAINER))
        wait(for: [expectation], timeout: 10.0)
        
        let responseData = callback.receivedResponse
        XCTAssertEqual(responseData,  ErrorCodes.DUPLICATE_ELEMENT_FOUND(values: ["card_number", "persons"]).description)
    }
    
    func testCreateRequestBodyDuplicatedAdditionalField() {
        let window = UIWindow()
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let options = CollectElementOptions(required: false)
        let collectInput1 = CollectElementInput(tableName: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
        let cardNumber = container?.create(input: collectInput1, options: options)
        cardNumber?.textField.secureText = "4111 1111 1111 1111"
        window.addSubview(cardNumber!)
        
        let collectInput2 = CollectElementInput(tableName: "persons", column: "cvv", placeholder: "cvv", type: .CVV)
        let cvv = container?.create(input: collectInput2, options: options)
        cvv?.textField.secureText = "211"
        window.addSubview(cvv!)
        let expectation = XCTestExpectation(description: "Container insert call - All valid")
        let callback = DemoAPICallback(expectation: expectation)
        
        let fields = AdditionalFields(records: [
            AdditionalFieldsRecord(tableName: "persons", data: ["cvv": "123", "name": "John Doe"])
        ])
        CollectRequestBuilder.createCollectRecords(elements: [cardNumber!, cvv!], additionalFields: fields,callback: callback, contextOptions: ContextOptions(interface: .COLLECT_CONTAINER))
        wait(for: [expectation], timeout: 10.0)

        let responseData = callback.receivedResponse
        XCTAssertEqual(responseData,  ErrorCodes.DUPLICATE_ELEMENT_FOUND(values: ["cvv", "persons"]).description)
    }

    func testCreateRequestBodyDuplicateInAdditionalFields() {
        let window = UIWindow()
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let options = CollectElementOptions(required: false)
        let collectInput1 = CollectElementInput(tableName: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
        let cardNumber = container?.create(input: collectInput1, options: options)
        cardNumber?.textField.secureText = "4111 1111 1111 1111"
        window.addSubview(cardNumber!)
        
        let collectInput2 = CollectElementInput(tableName: "persons", column: "cvv", placeholder: "cvv", type: .CVV)
        let cvv = container?.create(input: collectInput2, options: options)
        cvv?.textField.secureText = "211"
        window.addSubview(cvv!)
        let expectation = XCTestExpectation(description: "Container insert call - All valid")
        let callback = DemoAPICallback(expectation: expectation)
        
        let fields = AdditionalFields(records: [
            AdditionalFieldsRecord(tableName: "persons", data: ["duplicate": "123", "name": "John Doe"]),
            AdditionalFieldsRecord(tableName: "persons", data: ["duplicate": "123"])
        ])
        CollectRequestBuilder.createCollectRecords(elements: [cardNumber!, cvv!], additionalFields: fields,callback: callback, contextOptions: ContextOptions(interface: .COLLECT_CONTAINER))
        wait(for: [expectation], timeout: 10.0)

        let responseData = callback.receivedResponse
        XCTAssertEqual(responseData,  ErrorCodes.DUPLICATE_ADDITIONAL_FIELD_FOUND(value: "duplicate").description)
    }
    func testCreateRequestInsertBodyDuplicateInAdditionalFields() {
        let window = UIWindow()
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let options = CollectElementOptions(required: false)
        let collectInput1 = CollectElementInput(tableName: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
        let cardNumber = container?.create(input: collectInput1, options: options)
        cardNumber?.textField.secureText = "4111 1111 1111 1111"
        window.addSubview(cardNumber!)
        
        let collectInput2 = CollectElementInput(tableName: "persons", column: "cvv", placeholder: "cvv", type: .CVV)
        let cvv = container?.create(input: collectInput2, options: options)
        cvv?.textField.secureText = "211"
        window.addSubview(cvv!)
        let expectation = XCTestExpectation(description: "Container insert call - All valid")
        let callback = DemoAPICallback(expectation: expectation)
        
        let fields = AdditionalFields(records: [
            AdditionalFieldsRecord(tableName: "persons", data: ["cvv": "123"]),
            AdditionalFieldsRecord(tableName: "persons", data: ["duplicate": "123"])
        ])
        CollectRequestBuilder.createCollectRecords(elements: [cardNumber!, cvv!], additionalFields: fields,callback: callback, contextOptions: ContextOptions(interface: .COLLECT_CONTAINER))
        wait(for: [expectation], timeout: 10.0)

        let responseData = callback.receivedResponse
        XCTAssertEqual(responseData,  ErrorCodes.DUPLICATE_ELEMENT_FOUND(values: ["cvv", "persons"]).description)
    }

    func testCreateRequestBodyWithOnlyInserts() {
        let window = UIWindow()
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let options = CollectElementOptions(required: false)
        let collectInput1 = CollectElementInput(tableName: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
        let cardNumber = container?.create(input: collectInput1, options: options)
        cardNumber?.textField.secureText = "4111 1111 1111 1111"
        window.addSubview(cardNumber!)
        
        let collectInput2 = CollectElementInput(tableName: "persons", column: "cvv", placeholder: "cvv", type: .CVV)
        let cvv = container?.create(input: collectInput2, options: options)
        cvv?.textField.secureText = "211"
        window.addSubview(cvv!)
        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Insert only"))
        let requestBody = CollectRequestBuilder.createCollectRecords(elements: [cardNumber!, cvv!], callback: callback, contextOptions: ContextOptions())
        XCTAssertNotNil(requestBody)
        XCTAssertNotNil(requestBody?["records"])
        XCTAssertEqual(requestBody?["records"] as! [NSDictionary], [
            ["table": "persons", "fields": ["card_number": "", "cvv": ""]]
        ])
        // Every plain CollectElementInput defaults to skyflowId: "" (not nil) - confirms that
        // default doesn't accidentally get treated as "update targeting an empty ID".
        XCTAssertTrue((requestBody?["update"] as! [String: Any]).isEmpty)
    }

    func testCreateRequestBodyExplicitEmptyStringSkyflowIdOnElementIsRejected() {
        // An explicit empty-string skyflowId is rejected client-side (see
        // skyflow_iOS_emptySkyflowIdValidationTests) rather than silently falling back to insert.
        let window = UIWindow()
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let options = CollectElementOptions(required: false)
        let collectInput = CollectElementInput(tableName: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER, skyflowId: "")
        let cardNumber = container?.create(input: collectInput, options: options)
        cardNumber?.textField.secureText = "4111 1111 1111 1111"
        window.addSubview(cardNumber!)

        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Explicit empty-string skyflowId is rejected"))
        let requestBody = CollectRequestBuilder.createCollectRecords(elements: [cardNumber!], callback: callback, contextOptions: ContextOptions())

        XCTAssertNil(requestBody)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.EMPTY_SKYFLOW_ID(value: "element with column 'card_number'").description)
    }

    func testCreateRequestBodyWithSkyflowIDInAdditionalFields() {
        let additionalFields = AdditionalFields(records: [
            AdditionalFieldsRecord(tableName: "table1", data: ["column1": "value1"], skyflowId: "id1")
        ])
        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Update via additionalFields"))
        let requestBody = CollectRequestBuilder.createCollectRecords(elements: [], additionalFields: additionalFields, callback: callback, contextOptions: ContextOptions())
        XCTAssertNotNil(requestBody)
        XCTAssertEqual((requestBody?["records"] as! [[String: Any]]).count, 0)
        let update = requestBody?["update"] as! [String: Any]
        let entry = update["id1"] as! [String: Any]
        XCTAssertEqual(entry["table"] as! String, "table1")
        XCTAssertEqual(entry["fields"] as! [String: String], ["column1": "value1"])
    }

    func testCreateRequestBodyEmptyStringSkyflowIdOnAdditionalFieldsIsRejected() {
        // An explicit empty-string skyflowId is rejected client-side (see
        // skyflow_iOS_emptySkyflowIdValidationTests) rather than silently falling back to insert.
        let additionalFields = AdditionalFields(records: [
            AdditionalFieldsRecord(tableName: "table1", data: ["column1": "value1"], skyflowId: "")
        ])
        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Empty skyflowId is rejected"))
        let requestBody = CollectRequestBuilder.createCollectRecords(elements: [], additionalFields: additionalFields, callback: callback, contextOptions: ContextOptions())

        XCTAssertNil(requestBody)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.EMPTY_SKYFLOW_ID(value: "additional fields record at index 0").description)
    }

    func testCreateRequestBodyMergesMultipleAdditionalFieldsSharingSkyflowId() {
        // Two additionalFields entries that both target the same skyflowId should merge their
        // fields into a single update payload entry, not clobber or duplicate it.
        let additionalFields = AdditionalFields(records: [
            AdditionalFieldsRecord(tableName: "persons", data: ["name": "John"], skyflowId: "id1"),
            AdditionalFieldsRecord(tableName: "persons", data: ["email": "john@example.com"], skyflowId: "id1")
        ])
        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Merge additionalFields sharing a skyflowId"))
        let requestBody = CollectRequestBuilder.createCollectRecords(elements: [], additionalFields: additionalFields, callback: callback, contextOptions: ContextOptions())

        XCTAssertNotNil(requestBody)
        let update = requestBody?["update"] as! [String: Any]
        XCTAssertEqual(update.count, 1)
        let entry = update["id1"] as! [String: Any]
        XCTAssertEqual(entry["table"] as! String, "persons")
        let fields = entry["fields"] as! [String: String]
        XCTAssertEqual(fields["name"], "John")
        XCTAssertEqual(fields["email"], "john@example.com")
    }

    func testCreateRequestBodyWithSkyflowIDOnElement() {
        let window = UIWindow()
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let options = CollectElementOptions(required: false)
        let collectInput1 = CollectElementInput(tableName: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER, skyflowId: "id1")
        let cardNumber = container?.create(input: collectInput1, options: options)
        cardNumber?.textField.secureText = "4111 1111 1111 1111"
        window.addSubview(cardNumber!)

        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Update via element skyflowID"))
        let requestBody = CollectRequestBuilder.createCollectRecords(elements: [cardNumber!], callback: callback, contextOptions: ContextOptions())
        XCTAssertNotNil(requestBody)
        XCTAssertEqual((requestBody?["records"] as! [[String: Any]]).count, 0)
        let update = requestBody?["update"] as! [String: Any]
        let entry = update["id1"] as! [String: Any]
        XCTAssertEqual(entry["table"] as! String, "persons")
        XCTAssertEqual(entry["fields"] as! [String: String], ["card_number": ""])
    }

    func testCreateRequestBodyMixedInsertAndUpdateElements() {
        // One plain element (no skyflowId) and one update-by-skyflowId element in the same
        // collect() call - the plain one should land in "records", the tagged one in "update",
        // without either bucket interfering with the other.
        let window = UIWindow()
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let options = CollectElementOptions(required: false)

        let insertInput = CollectElementInput(tableName: "cards", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
        let insertElement = container?.create(input: insertInput, options: options)
        insertElement?.textField.secureText = "4111 1111 1111 1111"
        window.addSubview(insertElement!)

        let updateInput = CollectElementInput(tableName: "persons", column: "name", placeholder: "name", type: .CARDHOLDER_NAME, skyflowId: "id1")
        let updateElement = container?.create(input: updateInput, options: options)
        updateElement?.textField.secureText = "John Doe"
        window.addSubview(updateElement!)

        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Mixed insert and update elements"))
        let requestBody = CollectRequestBuilder.createCollectRecords(elements: [insertElement!, updateElement!], callback: callback, contextOptions: ContextOptions())

        XCTAssertNotNil(requestBody)
        let records = requestBody?["records"] as! [[String: Any]]
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0]["table"] as! String, "cards")

        let update = requestBody?["update"] as! [String: Any]
        XCTAssertEqual(update.count, 1)
        let updateEntry = update["id1"] as! [String: Any]
        XCTAssertEqual(updateEntry["table"] as! String, "persons")
    }

    func testCreateRequestBodyPlainInsertViaAdditionalFieldsCombinedWithElement() {
        // additionalFields without a skyflowId is a plain insert, same as a mounted element -
        // both should end up in "records" together, none in "update".
        let window = UIWindow()
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let options = CollectElementOptions(required: false)

        let insertInput = CollectElementInput(tableName: "cards", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
        let insertElement = container?.create(input: insertInput, options: options)
        insertElement?.textField.secureText = "4111 1111 1111 1111"
        window.addSubview(insertElement!)

        let additionalFields = AdditionalFields(records: [
            AdditionalFieldsRecord(tableName: "accounts", data: ["status": "active"])
        ])

        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Element insert + additionalFields insert"))
        let requestBody = CollectRequestBuilder.createCollectRecords(elements: [insertElement!], additionalFields: additionalFields, callback: callback, contextOptions: ContextOptions())

        XCTAssertNotNil(requestBody)
        let records = requestBody?["records"] as! [[String: Any]]
        XCTAssertEqual(records.count, 2)
        XCTAssertTrue(records.contains { $0["table"] as? String == "cards" })
        XCTAssertTrue(records.contains { $0["table"] as? String == "accounts" })

        let update = requestBody?["update"] as! [String: Any]
        XCTAssertTrue(update.isEmpty)
    }

    func testCreateRequestBodyElementUpdateWithAdditionalFieldsInsert() {
        // An update-by-skyflowId element combined with a plain-insert additionalFields record -
        // "records" should only contain the additionalFields insert, "update" only the element.
        let window = UIWindow()
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let options = CollectElementOptions(required: false)

        let updateInput = CollectElementInput(tableName: "persons", column: "name", placeholder: "name", type: .CARDHOLDER_NAME, skyflowId: "id1")
        let updateElement = container?.create(input: updateInput, options: options)
        updateElement?.textField.secureText = "John Doe"
        window.addSubview(updateElement!)

        let additionalFields = AdditionalFields(records: [
            AdditionalFieldsRecord(tableName: "accounts", data: ["status": "active"])
        ])

        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Element update + additionalFields insert"))
        let requestBody = CollectRequestBuilder.createCollectRecords(elements: [updateElement!], additionalFields: additionalFields, callback: callback, contextOptions: ContextOptions())

        XCTAssertNotNil(requestBody)
        let records = requestBody?["records"] as! [[String: Any]]
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0]["table"] as! String, "accounts")

        let update = requestBody?["update"] as! [String: Any]
        XCTAssertEqual(update.count, 1)
        XCTAssertEqual((update["id1"] as! [String: Any])["table"] as! String, "persons")
    }

    func testFullCombinationCollectUpdateUpsertAndAdditionalFields() {
        // The kitchen-sink scenario: an insert element, an update-by-skyflowId element, an
        // insert additionalFields record, and an update additionalFields record, all in one
        // request - then upsert applied on top. Upsert only ever touches CollectRequestBuilder.createInsertRequestBody's
        // "records" bucket (confirmed: CollectRequestBuilder.createUpdateRequestBody never reads options.upsert at
        // all), so it should only decorate the matching insert record and leave "update" untouched.
        let window = UIWindow()
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let options = CollectElementOptions(required: false)

        let insertInput = CollectElementInput(tableName: "cards", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
        let insertElement = container?.create(input: insertInput, options: options)
        insertElement?.textField.secureText = "4111 1111 1111 1111"
        window.addSubview(insertElement!)

        let updateInput = CollectElementInput(tableName: "persons", column: "name", placeholder: "name", type: .CARDHOLDER_NAME, skyflowId: "id1")
        let updateElement = container?.create(input: updateInput, options: options)
        updateElement?.textField.secureText = "John Doe"
        window.addSubview(updateElement!)

        let additionalFields = AdditionalFields(records: [
            AdditionalFieldsRecord(tableName: "accounts", data: ["status": "active"]),
            AdditionalFieldsRecord(tableName: "billing", data: ["zip": "94105"], skyflowId: "id2")
        ])

        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Full combination"))
        let requestBody = CollectRequestBuilder.createCollectRecords(elements: [insertElement!, updateElement!], additionalFields: additionalFields, callback: callback, contextOptions: ContextOptions())
        XCTAssertNotNil(requestBody)

        let records = requestBody?["records"] as! [[String: Any]]
        XCTAssertEqual(records.count, 2)
        XCTAssertTrue(records.contains { $0["table"] as? String == "cards" })
        XCTAssertTrue(records.contains { $0["table"] as? String == "accounts" })

        let update = requestBody?["update"] as! [String: Any]
        XCTAssertEqual(update.count, 2)
        XCTAssertEqual((update["id1"] as! [String: Any])["table"] as! String, "persons")
        XCTAssertEqual((update["id2"] as! [String: Any])["table"] as! String, "billing")

        // Apply upsert on top, matching only the "cards" table.
        let upsertOptions = [UpsertOptions(tableName: "cards", uniqueColumns: ["card_number"], updateType: .UPDATE)]
        let wireBody = CollectRequestBuilder.createInsertRequestBody(vaultID: "vault123", records: requestBody!, upsert: upsertOptions)
        let wireRecords = wireBody["records"] as! [[String: Any]]

        let cardsWireRecord = wireRecords.first { $0["tableName"] as? String == "cards" }
        XCTAssertNotNil(cardsWireRecord?["upsert"])

        let accountsWireRecord = wireRecords.first { $0["tableName"] as? String == "accounts" }
        XCTAssertNil(accountsWireRecord?["upsert"])

        // update bucket is a completely separate path (CollectRequestBuilder.createUpdateRequestBody) - upsert has
        // no way to reach or affect it, confirmed structurally since CollectRequestBuilder.createInsertRequestBody
        // only ever reads requestBody["records"].
        XCTAssertEqual(update.count, 2)
    }

    // Not currently reachable from any documented flow (README only shows ElementValueMatchRule
    // used to allow a duplicate plain/insert element, not two update-by-skyflowId elements), but
    // the code path exists in CollectRequestBuilder's update branch too - covering it now
    // in case a future update UI (e.g. confirm-password-style re-entry on an editable field) relies on it.
    func testCreateRequestBodyElementValueMatchRuleBypassesUpdateDuplicate() {
        let window = UIWindow()
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let options = CollectElementOptions(required: false)

        let updateInput1 = CollectElementInput(tableName: "persons", column: "name", placeholder: "name", type: .CARDHOLDER_NAME, skyflowId: "id1")
        let updateElement1 = container?.create(input: updateInput1, options: options)
        updateElement1?.textField.secureText = "John"
        updateElement1?.textFieldDidEndEditing(updateElement1!.textField)
        window.addSubview(updateElement1!)

        var vs = ValidationSet()
        vs.add(rule: ElementValueMatchRule(element: updateElement1!, error: "ELEMENT NOT MATCHING"))
        let updateInput2 = CollectElementInput(tableName: "persons", column: "name", placeholder: "name", type: .CARDHOLDER_NAME, validations: vs, skyflowId: "id1")
        let updateElement2 = container?.create(input: updateInput2, options: options)
        updateElement2?.textField.secureText = "Jane"
        updateElement2?.textFieldDidEndEditing(updateElement2!.textField)
        window.addSubview(updateElement2!)

        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Should not fail"))
        let requestBody = CollectRequestBuilder.createCollectRecords(elements: [updateElement1!, updateElement2!], callback: callback, contextOptions: ContextOptions())

        XCTAssertNotNil(requestBody)
        let update = requestBody?["update"] as! [String: Any]
        XCTAssertEqual(update.count, 1)
        let entry = update["id1"] as! [String: Any]
        // Second element's value is skipped (continue), not merged over the first's.
        XCTAssertEqual((entry["fields"] as! [String: String])["name"], "John")
    }

    func testCollectCallbackOnFailureParsesStructuredAPIError() {
        let wholeRequestFailure: [String: Any] = [
            "error": [
                "grpcCode": 13,
                "httpCode": 500,
                "message": "Skyflow services experienced an internal error. Contact Skyflow support with request ID 2db2c594-b9a5-48db-a220-f936e12a43e9 for more information.",
                "httpStatus": "Internal Server Error",
                "details": []
            ]
        ]
        var receivedError: SkyflowError?
        let collectCallback = CollectCallback(
            onSuccess: { _ in XCTFail("onSuccess should not be called") },
            onFailure: { error in receivedError = error }
        )

        collectCallback.onFailure(wholeRequestFailure)

        XCTAssertEqual(receivedError?.httpCode, 500)
        XCTAssertEqual(receivedError?.message, "Skyflow services experienced an internal error. Contact Skyflow support with request ID 2db2c594-b9a5-48db-a220-f936e12a43e9 for more information.")
        XCTAssertEqual(receivedError?.grpcCode, 13)
        XCTAssertEqual(receivedError?.httpStatus, "Internal Server Error")
        XCTAssertEqual(receivedError?.details?.count, 0)
    }

}
