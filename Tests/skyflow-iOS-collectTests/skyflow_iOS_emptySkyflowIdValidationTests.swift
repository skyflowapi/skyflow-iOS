/*
 * Copyright (c) 2022 Skyflow
*/

// Unit tests for the EMPTY_SKYFLOW_ID validation in FlowVaultCollectRequestBody:
// an explicit empty-string skyflowId (on an element or an additionalFields record)
// is rejected client-side instead of silently falling back to an insert.

import XCTest
@testable import SkyflowFlowVaultIOS
@testable import SkyflowCore

final class skyflow_iOS_emptySkyflowIdValidationTests: XCTestCase {
    var skyflow: Client!

    override func setUp() {
        self.skyflow = Client(Configuration(vaultID: "id", vaultURL: "http://demo.com", tokenProvider: DemoTokenProvider(), options: Options(logLevel: .DEBUG)))
    }

    override func tearDown() {
        skyflow = nil
    }

    private func makeNameElement(skyflowId: String? = nil) -> TextField {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let input = CollectElementInput(tableName: "persons", column: "name", type: .CARDHOLDER_NAME, skyflowId: skyflowId)
        let element = container!.create(input: input, options: CollectElementOptions(required: false))
        element.textField.secureText = "John Doe"
        // secureText's setter doesn't sync actualValue on its own - that normally happens via
        // the textFieldDidChange delegate hook, which a direct assignment here bypasses.
        element.updateActualValue()
        return element
    }

    func testAdditionalFieldsEmptySkyflowIdRejected() {
        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Empty skyflowId in additionalFields"))
        let additionalFields = AdditionalFields(records: [
            AdditionalFieldsRecord(tableName: "persons", data: ["name": "demo"], skyflowId: "")
        ])

        let requestBody = FlowVaultCollectRequestBody.createRequestBody(elements: [], additionalFields: additionalFields, callback: callback, contextOptions: ContextOptions())

        XCTAssertNil(requestBody)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.EMPTY_SKYFLOW_ID(value: "additional fields record at index 0").description)
    }

    func testAdditionalFieldsEmptySkyflowIdReportsRecordIndex() {
        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Index of offending record"))
        let additionalFields = AdditionalFields(records: [
            AdditionalFieldsRecord(tableName: "persons", data: ["name": "demo"], skyflowId: "valid-id"),
            AdditionalFieldsRecord(tableName: "persons", data: ["age": "30"], skyflowId: "")
        ])

        let requestBody = FlowVaultCollectRequestBody.createRequestBody(elements: [], additionalFields: additionalFields, callback: callback, contextOptions: ContextOptions())

        XCTAssertNil(requestBody)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.EMPTY_SKYFLOW_ID(value: "additional fields record at index 1").description)
    }

    func testElementEmptySkyflowIdRejected() {
        let element = makeNameElement(skyflowId: "")
        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Empty skyflowId on element"))

        let requestBody = FlowVaultCollectRequestBody.createRequestBody(elements: [element], callback: callback, contextOptions: ContextOptions())

        XCTAssertNil(requestBody)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.EMPTY_SKYFLOW_ID(value: "element with column 'name'").description)
    }

    func testNilSkyflowIdDefaultsToInsert() {
        let element = makeNameElement()
        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Nil skyflowId inserts"))
        let additionalFields = AdditionalFields(records: [
            AdditionalFieldsRecord(tableName: "table1", data: ["email": "a@b.com"])
        ])

        let requestBody = FlowVaultCollectRequestBody.createRequestBody(elements: [element], additionalFields: additionalFields, callback: callback, contextOptions: ContextOptions())

        XCTAssertNotNil(requestBody)
        let records = requestBody?["records"] as! [[String: Any]]
        XCTAssertEqual(records.count, 2)
        let update = requestBody?["update"] as! [String: Any]
        XCTAssertTrue(update.isEmpty)
    }

    func testCollectElementInputSkyflowIdDefaultsToNil() {
        let input = CollectElementInput(tableName: "persons", column: "name", type: .CARDHOLDER_NAME)
        XCTAssertNil(input.data.skyflowId)
    }

    func testValidSkyflowIdStillCreatesUpdate() {
        let element = makeNameElement(skyflowId: "row-1")
        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Valid skyflowId updates"))

        let requestBody = FlowVaultCollectRequestBody.createRequestBody(elements: [element], callback: callback, contextOptions: ContextOptions())

        XCTAssertNotNil(requestBody)
        XCTAssertEqual((requestBody?["records"] as! [[String: Any]]).count, 0)
        let update = requestBody?["update"] as! [String: Any]
        let entry = update["row-1"] as! [String: Any]
        XCTAssertEqual(entry["table"] as? String, "persons")
        XCTAssertEqual((entry["fields"] as! [String: Any])["name"] as? String, "John Doe")
    }
}
