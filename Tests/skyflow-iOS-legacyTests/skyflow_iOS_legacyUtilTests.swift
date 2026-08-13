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

    // v1 upsert validation (untyped upsert dicts), now in RequestValidators like the
    // FlowVault SDK's checkUpsertOptions; the operations deliver the returned error.

    func testCheckUpsertOptionsValid() {
        let upsert: [[String: Any]] = [["table": "table1", "column": "email"]]

        XCTAssertNil(RequestValidators.checkUpsertOptions(upsert))
    }

    func testCheckUpsertOptionsEmptyArray() {
        let errorCode = RequestValidators.checkUpsertOptions([])

        XCTAssertEqual(errorCode?.getErrorObject(contextOptions: ContextOptions()).localizedDescription,
                       ErrorCodes.UPSERT_OPTION_CANNOT_BE_EMPTY().getErrorObject(contextOptions: ContextOptions()).localizedDescription)
    }

    func testCheckUpsertOptionsMissingTableKey() {
        let upsert: [[String: Any]] = [["column": "email"]]
        let errorCode = RequestValidators.checkUpsertOptions(upsert)

        XCTAssertEqual(errorCode?.getErrorObject(contextOptions: ContextOptions()).localizedDescription,
                       ErrorCodes.MISSING_TABLE_NAME_IN_USERT_OPTION(value: "0").getErrorObject(contextOptions: ContextOptions()).localizedDescription)
    }

    func testCheckUpsertOptionsMissingColumnKey() {
        let upsert: [[String: Any]] = [["table": "table1"]]
        let errorCode = RequestValidators.checkUpsertOptions(upsert)

        XCTAssertEqual(errorCode?.getErrorObject(contextOptions: ContextOptions()).localizedDescription,
                       ErrorCodes.MISSING_COLUMN_NAME_IN_USERT_OPTION(value: "0").getErrorObject(contextOptions: ContextOptions()).localizedDescription)
    }

    func testCheckUpsertOptionsEmptyTableValue() {
        let upsert: [[String: Any]] = [["table": "", "column": "email"]]
        let errorCode = RequestValidators.checkUpsertOptions(upsert)

        XCTAssertEqual(errorCode?.getErrorObject(contextOptions: ContextOptions()).localizedDescription,
                       ErrorCodes.TABLE_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(value: "0").getErrorObject(contextOptions: ContextOptions()).localizedDescription)
    }

    func testCheckUpsertOptionsEmptyColumnValue() {
        let upsert: [[String: Any]] = [["table": "table1", "column": ""]]
        let errorCode = RequestValidators.checkUpsertOptions(upsert)

        XCTAssertEqual(errorCode?.getErrorObject(contextOptions: ContextOptions()).localizedDescription,
                       ErrorCodes.COLUMN_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(value: "0").getErrorObject(contextOptions: ContextOptions()).localizedDescription)
    }
}
