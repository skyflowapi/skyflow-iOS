/*
 * Copyright (c) 2022 Skyflow
*/

// Unit tests for the dormant v1 PDB CollectRequestBody (kept for potential future PDB reuse).
// Distinct from FlowVaultCollectRequestBody, which is the live class covering this same logic.

import XCTest
@testable import Skyflow

final class skyflow_iOS_dormantCollectRequestBodyTests: XCTestCase {
    var skyflow: Client!

    override func setUp() {
        self.skyflow = Client(Configuration(vaultID: "id", vaultURL: "http://demo.com", tokenProvider: DemoTokenProvider(), options: Options(logLevel: .DEBUG)))
    }

    func testCreateRequestBodySimpleInsert() {
        let window = UIWindow()
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let options = CollectElementOptions(required: false)

        let cardNumberInput = CollectElementInput(table: "persons", column: "card_number", type: .CARD_NUMBER)
        let cardNumber = container?.create(input: cardNumberInput, options: options)
        cardNumber?.textField.secureText = "4111 1111 1111 1111"
        window.addSubview(cardNumber!)

        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Pure insert"))
        let requestBody = CollectRequestBody.createRequestBody(elements: [cardNumber!], callback: callback, contextOptions: ContextOptions())

        XCTAssertNotNil(requestBody)
        let records = requestBody?["records"] as! [[String: Any]]
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0]["table"] as? String, "persons")
        let update = requestBody?["update"] as! [String: Any]
        XCTAssertTrue(update.isEmpty)
    }

    func testCreateRequestBodyWithSkyflowIDInAdditionalFields() {
        let additionalFields: [String: Any] = [
            "records": [
                ["table": "table1", "fields": ["column1": "value1"], "skyflowId": "id1"]
            ]
        ]
        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Update via additionalFields"))
        let requestBody = CollectRequestBody.createRequestBody(elements: [], additionalFields: additionalFields, callback: callback, contextOptions: ContextOptions())

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

        let cardNumberInput = CollectElementInput(table: "persons", column: "card_number", type: .CARD_NUMBER, skyflowId: "id1")
        let cardNumber = container?.create(input: cardNumberInput, options: options)
        cardNumber?.textField.secureText = "4111 1111 1111 1111"
        window.addSubview(cardNumber!)

        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Update via element skyflowID"))
        let requestBody = CollectRequestBody.createRequestBody(elements: [cardNumber!], callback: callback, contextOptions: ContextOptions())

        XCTAssertNotNil(requestBody)
        XCTAssertEqual((requestBody?["records"] as! [[String: Any]]).count, 0)
        let update = requestBody?["update"] as! [String: Any]
        let entry = update["id1"] as! [String: Any]
        XCTAssertEqual(entry["table"] as! String, "persons")
        XCTAssertEqual(entry["fields"] as! [String: String], ["card_number": ""])
    }

    func testCreateRequestBodyDuplicateAdditionalFieldError() {
        let additionalFields: [String: Any] = [
            "records": [
                ["table": "table1", "fields": ["column1": "value1"]],
                ["table": "table1", "fields": ["column1": "value2"]]
            ]
        ]
        let expectation = XCTestExpectation(description: "Duplicate additional field should fail")
        let callback = DemoAPICallback(expectation: expectation)
        let requestBody = CollectRequestBody.createRequestBody(elements: [], additionalFields: additionalFields, callback: callback, contextOptions: ContextOptions())

        XCTAssertNil(requestBody)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.DUPLICATE_ADDITIONAL_FIELD_FOUND(value: "column1").getErrorObject(contextOptions: ContextOptions()).localizedDescription)
    }

    func testGetUniqueColumn() {
        let upsert: [[String: Any]] = [
            ["table": "table1", "column": "email"],
            ["table": "table2", "column": "ssn"]
        ]

        XCTAssertEqual(CollectRequestBody.getUniqueColumn(tableName: "table1", upsert: upsert), "email")
        XCTAssertEqual(CollectRequestBody.getUniqueColumn(tableName: "table2", upsert: upsert), "ssn")
        XCTAssertEqual(CollectRequestBody.getUniqueColumn(tableName: "table3", upsert: upsert), "")
    }
}
