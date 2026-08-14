/*
 * Copyright (c) 2022 Skyflow
*/

// Tests for FlowVault (v2) SDK-specific surface not covered elsewhere:
// initialize() identity, the public CollectCallback/RevealCallback wrappers
// and the typed option/input models.

import XCTest
@testable import SkyflowFlowVault
@testable import SkyflowCore

final class skyflow_iOS_flowVaultSdkTests: XCTestCase {

    // MARK: - initialize()

    func testInitializeStampsFlowVaultSdkName() {
        // SDK_NAME is a process-wide global shared with the legacy SDK's
        // tests (and asserted against its default by testGetDeviceDetails);
        // restore it so this test can't leak into other suites.
        let originalSdkName = SDK_NAME
        defer { SDK_NAME = originalSdkName }

        let client = SkyflowFlowVault.initialize(Configuration(
            vaultID: "vault_id",
            vaultURL: "https://example.org/",
            tokenProvider: DemoTokenProvider()))

        XCTAssertNotNil(client)
        XCTAssertEqual(SDK_NAME, "skyflow-flowvault-ios")
    }

    // MARK: - CollectCallback wrapper

    func testCollectCallbackUnwrapsValidResponse() {
        let expectation = XCTestExpectation(description: "success handler should receive CollectResponse")
        let callback = CollectCallback(
            onSuccess: { response in
                XCTAssertEqual(response.records.count, 2)
                XCTAssertNil(response.records[0].error)
                XCTAssertEqual(response.records[1].error, "failed")
                expectation.fulfill()
            },
            onFailure: { _ in XCTFail("valid body must not route to onFailure") })

        callback.onSuccess([
            "records": [
                ["tableName": "persons", "skyflowID": "id1", "httpCode": 200],
                ["error": "failed", "httpCode": 400]
            ]
        ] as [String: Any])

        wait(for: [expectation], timeout: 10.0)
    }

    func testCollectCallbackRoutesMalformedBodyToFailure() {
        let expectation = XCTestExpectation(description: "malformed body should route to onFailure")
        let callback = CollectCallback(
            onSuccess: { _ in XCTFail("malformed body must not route to onSuccess") },
            onFailure: { _ in expectation.fulfill() })

        callback.onSuccess("not a dictionary")

        wait(for: [expectation], timeout: 10.0)
    }

    func testCollectCallbackWrapsFailureAsSkyflowError() {
        let expectation = XCTestExpectation(description: "failure should be a normalized SkyflowError")
        let callback = CollectCallback(
            onSuccess: { _ in XCTFail("failure must not route to onSuccess") },
            onFailure: { error in
                XCTAssertEqual(error.message, "The Internet connection appears to be offline.")
                expectation.fulfill()
            })

        callback.onFailure(NSError(domain: "NSURLErrorDomain", code: -1009,
                                   userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."]))

        wait(for: [expectation], timeout: 10.0)
    }

    // MARK: - RevealCallback wrapper

    func testRevealCallbackUnwrapsValidResponse() {
        let expectation = XCTestExpectation(description: "success handler should receive RevealResponse")
        let callback = RevealCallback(
            onSuccess: { response in
                XCTAssertEqual(response.records.count, 1)
                XCTAssertEqual(response.records[0].token, "token1")
                expectation.fulfill()
            },
            onFailure: { _ in XCTFail("valid body must not route to onFailure") })

        callback.onSuccess(["records": [["token": "token1", "value": "John", "httpCode": 200]]] as [String: Any])

        wait(for: [expectation], timeout: 10.0)
    }

    func testRevealCallbackRoutesMalformedBodyToFailure() {
        let expectation = XCTestExpectation(description: "malformed body should route to onFailure")
        let callback = RevealCallback(
            onSuccess: { _ in XCTFail("malformed body must not route to onSuccess") },
            onFailure: { _ in expectation.fulfill() })

        callback.onSuccess(["records": "not an array"])

        wait(for: [expectation], timeout: 10.0)
    }

    func testRevealCallbackWrapsFailureAsSkyflowError() {
        let expectation = XCTestExpectation(description: "failure should be a normalized SkyflowError")
        let callback = RevealCallback(
            onSuccess: { _ in XCTFail("failure must not route to onSuccess") },
            onFailure: { error in
                XCTAssertEqual(error.message, "TokenProvider error")
                expectation.fulfill()
            })

        callback.onFailure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "TokenProvider error"]))

        wait(for: [expectation], timeout: 10.0)
    }

    // MARK: - Typed models

    func testUpsertOptionCarriesTypedFields() {
        let option = UpsertOption(tableName: "persons", uniqueColumns: ["email"], updateType: .REPLACE)

        XCTAssertEqual(option.tableName, "persons")
        XCTAssertEqual(option.uniqueColumns, ["email"])
        XCTAssertEqual(option.updateType, .REPLACE)
        XCTAssertNil(UpsertOption(tableName: "persons", uniqueColumns: ["email"]).updateType)
    }

    func testAdditionalFieldsRecordDefaultsToNilSkyflowId() {
        let record = AdditionalFieldsRecord(tableName: "persons", data: ["name": "john"])

        XCTAssertEqual(record.tableName, "persons")
        XCTAssertNil(record.skyflowId)

        let update = AdditionalFieldsRecord(tableName: "persons", data: ["name": "john"], skyflowId: "sid-1")
        XCTAssertEqual(update.skyflowId, "sid-1")
    }

    func testTokenGroupRedactionCarriesFields() {
        let redaction = TokenGroupRedaction(tokenGroupName: "deterministic_string", redaction: "MASKED")

        XCTAssertEqual(redaction.tokenGroupName, "deterministic_string")
        XCTAssertEqual(redaction.redaction, "MASKED")
    }

    // MARK: - RequestValidators valid (nil-returning) paths

    func testCheckRecordValidReturnsNil() {
        XCTAssertNil(RequestValidators.checkRecord(
            record: AdditionalFieldsRecord(tableName: "persons", data: ["name": "john"]), index: 0))
    }

    func testCheckAdditionalFieldsValidReturnsNil() {
        let additionalFields = AdditionalFields(records: [
            AdditionalFieldsRecord(tableName: "persons", data: ["name": "john"]),
            AdditionalFieldsRecord(tableName: "contacts", data: ["email": "a@b.com"], skyflowId: "sid-1")
        ])

        XCTAssertNil(RequestValidators.checkAdditionalFields(additionalFields))
    }

    func testCheckTokenGroupRedactionsValidReturnsNil() {
        XCTAssertNil(RequestValidators.checkTokenGroupRedactions([
            TokenGroupRedaction(tokenGroupName: "group", redaction: "MASKED")
        ]))
    }

    func testCheckUpsertOptionsValidReturnsNil() {
        XCTAssertNil(RequestValidators.checkUpsertOptions([
            UpsertOption(tableName: "persons", uniqueColumns: ["email"])
        ]))
    }

    // MARK: - Deprecated CollectElementInput initializer (backward compatibility)

    @available(*, deprecated) // silences the warning for exercising the deprecated altText: initializer
    func testCollectElementInputDeprecatedAltTextInit() {
        let input = CollectElementInput(tableName: "persons", column: "name", altText: "alt", type: .CARDHOLDER_NAME)

        XCTAssertEqual(input.data.tableName, "persons")
        XCTAssertEqual(input.data.column, "name")
    }
}
