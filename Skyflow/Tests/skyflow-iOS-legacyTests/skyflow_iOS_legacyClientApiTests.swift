/*
 * Copyright (c) 2022 Skyflow
*/

// Validation-path tests for the legacy (v1) public Client operations
// (insert/detokenize) and the legacy initialize() SDK identity.

import XCTest
@testable import Skyflow
@testable import SkyflowCore

final class skyflow_iOS_legacyClientApiTests: XCTestCase {
    var skyflow: Client!

    override func setUp() {
        self.skyflow = Client(Configuration(
            vaultID: "vault_id",
            vaultURL: "https://example.org/",
            tokenProvider: DemoTokenProvider(),
            options: Options(logLevel: .DEBUG)))
    }

    override func tearDown() {
        skyflow = nil
    }

    // MARK: - initialize()

    func testInitializeStampsLegacySdkName() {
        // SDK_NAME is a process-wide global shared with the FlowVault SDK's
        // tests; restore it so this test can't leak into other suites.
        let originalSdkName = SDK_NAME
        defer { SDK_NAME = originalSdkName }

        let client = Skyflow.initialize(Configuration(
            vaultID: "vault_id",
            vaultURL: "https://example.org/",
            tokenProvider: DemoTokenProvider()))

        XCTAssertNotNil(client)
        XCTAssertEqual(SDK_NAME, "skyflow-iOS")
    }

    // MARK: - insert() validation (failures delivered as a raw NSError)

    func testInsertMissingRecordsKey() {
        let expectation = XCTestExpectation(description: "insert without records key should fail")
        let callback = DemoAPICallback(expectation: expectation)

        skyflow.insert(records: ["norecords": []], callback: callback)

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.RECORDS_KEY_ERROR().description)
    }

    func testInsertInvalidRecordsType() {
        let expectation = XCTestExpectation(description: "insert with non-array records should fail")
        let callback = DemoAPICallback(expectation: expectation)

        skyflow.insert(records: ["records": "not an array"], callback: callback)

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.INVALID_RECORDS_TYPE().description)
    }

    func testInsertInvalidTableNameType() {
        let expectation = XCTestExpectation(description: "insert with non-string table should fail")
        let callback = DemoAPICallback(expectation: expectation)

        skyflow.insert(records: ["records": [["table": 1, "fields": ["a": "b"]]]], callback: callback)

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.INVALID_TABLE_NAME_TYPE(value: "0").description)
    }

    func testInsertMissingTableKey() {
        let expectation = XCTestExpectation(description: "insert with a record missing the table key should fail")
        let callback = DemoAPICallback(expectation: expectation)

        skyflow.insert(records: ["records": [["fields": ["a": "b"]]]], callback: callback)

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.TABLE_KEY_ERROR(value: "0").description)
    }

    func testInsertEmptyTableName() {
        let expectation = XCTestExpectation(description: "insert with an empty table name should fail")
        let callback = DemoAPICallback(expectation: expectation)

        skyflow.insert(records: ["records": [["table": "", "fields": ["a": "b"]]]], callback: callback)

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.EMPTY_TABLE_NAME().description)
    }

    func testInsertMissingFieldsKey() {
        let expectation = XCTestExpectation(description: "insert with a record missing the fields key should fail")
        let callback = DemoAPICallback(expectation: expectation)

        skyflow.insert(records: ["records": [["table": "persons"]]], callback: callback)

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.FIELDS_KEY_ERROR(value: "0").description)
    }

    func testInsertInvalidFieldsType() {
        let expectation = XCTestExpectation(description: "insert with a non-dictionary fields value should fail")
        let callback = DemoAPICallback(expectation: expectation)

        skyflow.insert(records: ["records": [["table": "persons", "fields": "not a dict"]]], callback: callback)

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.INVALID_FIELDS_TYPE(value: "0").description)
    }

    func testInsertEmptyFields() {
        let expectation = XCTestExpectation(description: "insert with an empty fields dictionary should fail")
        let callback = DemoAPICallback(expectation: expectation)

        skyflow.insert(records: ["records": [["table": "persons", "fields": [:] as [String: Any]]]], callback: callback)

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.EMPTY_FIELDS_KEY(value: "0").description)
    }

    func testInsertEmptyUpsertOptions() {
        let expectation = XCTestExpectation(description: "insert with empty upsert array should fail")
        let callback = DemoAPICallback(expectation: expectation)
        let records: [String: Any] = ["records": [["table": "persons", "fields": ["name": "john"]]]]

        skyflow.insert(records: records, options: InsertOptions(tokens: true, upsert: []), callback: callback)

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.UPSERT_OPTION_CANNOT_BE_EMPTY().description)
    }

    func testInsertEmptyVaultURL() {
        let expectation = XCTestExpectation(description: "insert with empty vaultURL should fail")
        let callback = DemoAPICallback(expectation: expectation)
        let client = Client(Configuration(vaultID: "vault_id", vaultURL: "", tokenProvider: DemoTokenProvider()))

        client.insert(records: ["records": [["table": "persons", "fields": ["name": "john"]]]], callback: callback)

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.EMPTY_VAULT_URL().description)
    }

    // MARK: - detokenize() validation (failures wrapped as {"errors": [NSError]})

    private func detokenizeError(records: [String: Any]) -> NSError? {
        let expectation = XCTestExpectation(description: "detokenize should fail")
        let callback = DemoAPICallback(expectation: expectation)

        skyflow.detokenize(records: records, callback: callback)

        wait(for: [expectation], timeout: 10.0)
        return (callback.data["errors"] as? [NSError])?.first
    }

    func testDetokenizeMissingRecordsKey() {
        let error = detokenizeError(records: ["norecords": []])

        XCTAssertEqual(error?.localizedDescription, ErrorCodes.RECORDS_KEY_ERROR().description)
    }

    func testDetokenizeEmptyRecords() {
        let error = detokenizeError(records: ["records": [] as [[String: Any]]])

        XCTAssertEqual(error?.localizedDescription, ErrorCodes.EMPTY_RECORDS_OBJECT().description)
    }

    func testDetokenizeInvalidRecordsType() {
        let error = detokenizeError(records: ["records": "not an array"])

        XCTAssertEqual(error?.localizedDescription, ErrorCodes.INVALID_RECORDS_TYPE().description)
    }

    func testDetokenizeMissingToken() {
        let error = detokenizeError(records: ["records": [["redaction": RedactionType.PLAIN_TEXT]]])

        XCTAssertEqual(error?.localizedDescription, ErrorCodes.ID_KEY_ERROR().description)
    }

    func testDetokenizeInvalidTokenType() {
        let error = detokenizeError(records: ["records": [["token": 123]]])

        XCTAssertEqual(error?.localizedDescription, ErrorCodes.INVALID_TOKEN_TYPE(value: "0").description)
    }

    func testDetokenizeInvalidRedactionType() {
        // Legacy detokenize takes redaction as a RedactionType enum value; a raw string must be rejected.
        let error = detokenizeError(records: ["records": [["token": "abc", "redaction": "PLAIN_TEXT"]]])

        XCTAssertEqual(error?.localizedDescription, ErrorCodes.INVALID_REDACTION_TYPE().description)
    }

    func testDetokenizeEmptyVaultID() {
        let expectation = XCTestExpectation(description: "detokenize with empty vaultID should fail")
        let callback = DemoAPICallback(expectation: expectation)
        let client = Client(Configuration(vaultID: "", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()))

        client.detokenize(records: ["records": [["token": "abc"]]], callback: callback)

        wait(for: [expectation], timeout: 10.0)
        let error = (callback.data["errors"] as? [NSError])?.first
        XCTAssertEqual(error?.localizedDescription, ErrorCodes.EMPTY_VAULT_ID().description)
    }

    // MARK: - Full request flows (valid input; the unresolvable vault host fails fast
    // at the network layer after the whole request-building path has executed)

    private func offlineClient() -> Client {
        return Client(Configuration(vaultID: "vault_id", vaultURL: "https://testvault.skyflow.invalid/",
                                    tokenProvider: DemoTokenProvider()))
    }

    func testInsertValidRecordsRunsFullRequestFlow() {
        let expectation = XCTestExpectation(description: "insert should reach the network layer and fail offline")
        let callback = DemoAPICallback(expectation: expectation)

        offlineClient().insert(records: ["records": [["table": "persons", "fields": ["name": "john"]]]],
                               callback: callback)

        wait(for: [expectation], timeout: 20.0)
        XCTAssertFalse(callback.receivedResponse.isEmpty && callback.data.isEmpty)
    }

    func testDetokenizeValidRecordsWithExplicitRedactionRunsFullRequestFlow() {
        let expectation = XCTestExpectation(description: "detokenize should reach the network layer and fail offline")
        let callback = DemoAPICallback(expectation: expectation)

        offlineClient().detokenize(records: ["records": [
            ["token": "tok1", "redaction": RedactionType.MASKED],
            ["token": "tok2"]
        ]], callback: callback)

        wait(for: [expectation], timeout: 20.0)
        XCTAssertNotNil(callback.data["errors"])
    }

    // MARK: - getById() validation branches

    private func getByIdError(records: [String: Any]) -> NSError? {
        let expectation = XCTestExpectation(description: "getById should fail")
        let callback = DemoAPICallback(expectation: expectation)

        skyflow.getById(records: records, callback: callback)

        wait(for: [expectation], timeout: 10.0)
        return (callback.data["errors"] as? [NSError])?.first
    }

    func testGetByIdMissingRecordsKey() {
        XCTAssertEqual(getByIdError(records: ["norecords": []])?.localizedDescription,
                       ErrorCodes.EMPTY_RECORDS_OBJECT().description)
    }

    func testGetByIdEmptyRecords() {
        XCTAssertEqual(getByIdError(records: ["records": [] as [[String: Any]]])?.localizedDescription,
                       ErrorCodes.EMPTY_RECORDS_OBJECT().description)
    }

    func testGetByIdInvalidRecordsType() {
        XCTAssertEqual(getByIdError(records: ["records": "not an array"])?.localizedDescription,
                       ErrorCodes.INVALID_RECORDS_TYPE().description)
    }

    func testGetByIdInvalidEntryReportsValidatorError() {
        XCTAssertEqual(getByIdError(records: ["records": [["table": "persons", "redaction": RedactionType.PLAIN_TEXT]]])?.localizedDescription,
                       ErrorCodes.MISSING_KEY_IDS(value: "0").description)
    }

    func testGetByIdValidRecordsRunsFullRequestFlow() {
        let expectation = XCTestExpectation(description: "getById should reach the network layer and fail offline")
        let callback = DemoAPICallback(expectation: expectation)

        offlineClient().getById(records: ["records": [
            ["ids": ["id1", "id2"], "table": "persons", "redaction": RedactionType.PLAIN_TEXT]
        ]], callback: callback)

        wait(for: [expectation], timeout: 20.0)
        XCTAssertNotNil(callback.data["errors"])
    }

    // MARK: - get() validation branches

    private func getError(records: [String: Any], options: GetOptions = GetOptions()) -> NSError? {
        let expectation = XCTestExpectation(description: "get should fail")
        let callback = DemoAPICallback(expectation: expectation)

        skyflow.get(records: records, options: options, callback: callback)

        wait(for: [expectation], timeout: 10.0)
        return (callback.data["errors"] as? [NSError])?.first
    }

    func testGetMissingRecordsKey() {
        XCTAssertEqual(getError(records: ["norecords": []])?.localizedDescription,
                       ErrorCodes.EMPTY_RECORDS_OBJECT().description)
    }

    func testGetEmptyRecords() {
        XCTAssertEqual(getError(records: ["records": [] as [[String: Any]]])?.localizedDescription,
                       ErrorCodes.EMPTY_RECORDS_OBJECT().description)
    }

    func testGetInvalidRecordsType() {
        XCTAssertEqual(getError(records: ["records": "not an array"])?.localizedDescription,
                       ErrorCodes.INVALID_RECORDS_TYPE().description)
    }

    func testGetValidIdsWithRedactionRunsFullRequestFlow() {
        let expectation = XCTestExpectation(description: "get by ids should reach the network layer and fail offline")
        let callback = DemoAPICallback(expectation: expectation)

        offlineClient().get(records: ["records": [
            ["ids": ["id1"], "table": "persons", "redaction": RedactionType.PLAIN_TEXT]
        ]], callback: callback)

        wait(for: [expectation], timeout: 20.0)
        XCTAssertNotNil(callback.data["errors"])
    }

    func testGetValidIdsWithTokensOptionRunsFullRequestFlow() {
        let expectation = XCTestExpectation(description: "get with tokens should reach the network layer and fail offline")
        let callback = DemoAPICallback(expectation: expectation)

        offlineClient().get(records: ["records": [["ids": ["id1"], "table": "persons"]]],
                            options: GetOptions(tokens: true), callback: callback)

        wait(for: [expectation], timeout: 20.0)
        XCTAssertNotNil(callback.data["errors"])
    }

    func testGetValidColumnValuesRunsFullRequestFlow() {
        let expectation = XCTestExpectation(description: "get by column values should reach the network layer and fail offline")
        let callback = DemoAPICallback(expectation: expectation)

        offlineClient().get(records: ["records": [
            ["table": "persons", "columnName": "email", "columnValues": ["a@b.com"], "redaction": RedactionType.PLAIN_TEXT]
        ]], callback: callback)

        wait(for: [expectation], timeout: 20.0)
        XCTAssertNotNil(callback.data["errors"])
    }

    // MARK: - createDetokenizeRecords

    func testCreateDetokenizeRecordsBuildsTokenList() {
        let records = skyflow.createDetokenizeRecords(["id1": "tok1"])

        XCTAssertEqual(records["records"], [["token": "tok1"]])
    }
}
