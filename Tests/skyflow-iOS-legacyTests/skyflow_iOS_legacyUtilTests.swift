/*
 * Copyright (c) 2022 Skyflow
*/

// Dormant v1 PDB helper tests (APIClient batch/upsert helpers and ICOptions).

import XCTest
@testable import Skyflow
@testable import SkyflowCore

final class skyflow_iOS_legacyUtilTests: XCTestCase {
    // Dormant v1 PDB helpers on APIClient (untyped upsert), kept for potential future PDB reuse.

    func testGetUniqueColumn() {
        let apiClient = APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider())
        let upsert: [[String: Any]] = [
            ["table": "table1", "column": "email"],
            ["table": "table2", "column": "ssn"]
        ]

        XCTAssertEqual(apiClient.getUniqueColumn(tableName: "table1", upsert: upsert), "email")
        XCTAssertEqual(apiClient.getUniqueColumn(tableName: "table2", upsert: upsert), "ssn")
        XCTAssertEqual(apiClient.getUniqueColumn(tableName: "table3", upsert: upsert), "")
    }

    func testConstructBatchRequestBodyWithUpsert() {
        let apiClient = APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider())
        let records: [String: Any] = ["records": [["table": "table1", "fields": ["email": "a@b.com"]]]]
        let upsert: [[String: Any]] = [["table": "table1", "column": "email"]]
        let options = ICOptions(tokens: false, upsert: upsert)

        let result = apiClient.constructBatchRequestBody(records: records, options: options)
        let postPayload = result["records"] as! [[String: Any]]

        XCTAssertEqual(postPayload.count, 1)
        XCTAssertEqual(postPayload[0]["upsert"] as? String, "email")
        XCTAssertEqual(postPayload[0]["tableName"] as? String, "table1")
        XCTAssertEqual(postPayload[0]["method"] as? String, "POST")
        XCTAssertEqual(postPayload[0]["quorum"] as? Bool, true)
    }

    func testConstructBatchRequestBodyWithTokensAddsGetStep() {
        let apiClient = APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider())
        let records: [String: Any] = ["records": [["table": "table1", "fields": ["email": "a@b.com"]]]]
        let options = ICOptions(tokens: true)

        let result = apiClient.constructBatchRequestBody(records: records, options: options)
        let postPayload = result["records"] as! [[String: Any]]

        // One POST insert entry, plus one GET tokenization entry appended after it.
        XCTAssertEqual(postPayload.count, 2)
        XCTAssertEqual(postPayload[0]["method"] as? String, "POST")
        XCTAssertEqual(postPayload[1]["method"] as? String, "GET")
        XCTAssertEqual(postPayload[1]["tokenization"] as? Bool, true)
        XCTAssertEqual(postPayload[1]["ID"] as? String, "$responses.0.records.0.skyflow_id")
    }

    func testConstructBatchRequestBodyNoUpsertNoTokens() {
        let apiClient = APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider())
        let records: [String: Any] = ["records": [["table": "table1", "fields": ["email": "a@b.com"]]]]
        let options = ICOptions(tokens: false)

        let result = apiClient.constructBatchRequestBody(records: records, options: options)
        let postPayload = result["records"] as! [[String: Any]]

        XCTAssertEqual(postPayload.count, 1)
        XCTAssertNil(postPayload[0]["upsert"])
    }

    // Dormant v1 ICOptions.validateUpsert() (untyped upsert dicts), kept for potential future
    // PDB reuse. Distinct from FlowVaultICOptions.validateUpsert(), which covers the live path.

    func testICOptionsValidateUpsertValid() {
        let callback = DemoAPICallback(expectation: XCTestExpectation())
        let upsert: [[String: Any]] = [["table": "table1", "column": "email"]]
        let options = ICOptions(tokens: false, upsert: upsert, callback: callback, contextOptions: ContextOptions())

        XCTAssertFalse(options.validateUpsert())
    }

    func testICOptionsValidateUpsertEmptyArray() {
        let expectation = XCTestExpectation()
        let callback = DemoAPICallback(expectation: expectation)
        let options = ICOptions(tokens: false, upsert: [], callback: callback, contextOptions: ContextOptions())

        XCTAssertTrue(options.validateUpsert())
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.UPSERT_OPTION_CANNOT_BE_EMPTY().getErrorObject(contextOptions: ContextOptions()).localizedDescription)
    }

    func testICOptionsValidateUpsertMissingTableKey() {
        let expectation = XCTestExpectation()
        let callback = DemoAPICallback(expectation: expectation)
        let upsert: [[String: Any]] = [["column": "email"]]
        let options = ICOptions(tokens: false, upsert: upsert, callback: callback, contextOptions: ContextOptions())

        XCTAssertTrue(options.validateUpsert())
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.MISSING_TABLE_NAME_IN_USERT_OPTION(value: "0").getErrorObject(contextOptions: ContextOptions()).localizedDescription)
    }

    func testICOptionsValidateUpsertMissingColumnKey() {
        let expectation = XCTestExpectation()
        let callback = DemoAPICallback(expectation: expectation)
        let upsert: [[String: Any]] = [["table": "table1"]]
        let options = ICOptions(tokens: false, upsert: upsert, callback: callback, contextOptions: ContextOptions())

        XCTAssertTrue(options.validateUpsert())
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.MISSING_COLUMN_NAME_IN_USERT_OPTION(value: "0").getErrorObject(contextOptions: ContextOptions()).localizedDescription)
    }

    func testICOptionsValidateUpsertEmptyTableValue() {
        let expectation = XCTestExpectation()
        let callback = DemoAPICallback(expectation: expectation)
        let upsert: [[String: Any]] = [["table": "", "column": "email"]]
        let options = ICOptions(tokens: false, upsert: upsert, callback: callback, contextOptions: ContextOptions())

        XCTAssertTrue(options.validateUpsert())
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.TABLE_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(value: "0").getErrorObject(contextOptions: ContextOptions()).localizedDescription)
    }

    func testICOptionsValidateUpsertEmptyColumnValue() {
        let expectation = XCTestExpectation()
        let callback = DemoAPICallback(expectation: expectation)
        let upsert: [[String: Any]] = [["table": "table1", "column": ""]]
        let options = ICOptions(tokens: false, upsert: upsert, callback: callback, contextOptions: ContextOptions())

        XCTAssertTrue(options.validateUpsert())
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.COLUMN_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(value: "0").getErrorObject(contextOptions: ContextOptions()).localizedDescription)
    }
}
