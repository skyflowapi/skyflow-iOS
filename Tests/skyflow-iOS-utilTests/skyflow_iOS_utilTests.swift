/*
 * Copyright (c) 2022 Skyflow
*/

import XCTest
@testable import Skyflow

final class skyflow_iOS_utilTests: XCTestCase {
    override func setUp() {
    }
    
    override func tearDown() {
    }
    
    func testGetFirstRegexMatch() {
        do {
            XCTAssertEqual(try "abcdef".getFirstRegexMatch(of: "..$", contextOptions: ContextOptions()), "ef")
        } catch {
            XCTFail()
        }
        
        do {
            try "abcdef".getFirstRegexMatch(of: "9$", contextOptions: ContextOptions())
            XCTFail()
        } catch {
            XCTAssertEqual((error as! NSError).code, ErrorCodes.REGEX_MATCH_FAILED().code)
            XCTAssert((error as NSError).localizedDescription.contains( ErrorCodes.REGEX_MATCH_FAILED().description))
        }
    }
    
    
    func testGetFormattedText() {
        XCTAssertEqual("2022".getFormattedText(with: "..$", contextOptions: ContextOptions(logLevel: .WARN)), "22")
        XCTAssertEqual("abcdef".getFormattedText(with: "9$", contextOptions: ContextOptions()), "abcdef")
        
        XCTAssertEqual("1".getFormattedText(with: "^([0-9])$", replacementString: "0$1", contextOptions: ContextOptions()), "01")
        XCTAssertEqual("12".getFormattedText(with: "^([0-9])$", replacementString: "0$1", contextOptions: ContextOptions()), "12")
    }
    
    func testFormatTextEmptyPattern() {
        let textField = FormatTextField()
        textField.leftViewRect(forBounds: CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: 10, height: 1.0)))
        let str = "text to format"
        let result = textField.formatText(str, NSRange(str.range(of: "text")!, in: str), true)
        XCTAssertEqual(str, result.formattedText)
    }
    
    func testFormatTextWithPattern() {
        let textField = FormatTextField()
        textField.formatPattern = "#### #### #### ####"
        let str = "4111111111111111"
        let result = textField.formatText(str, NSRange(str.range(of: str)!, in: str), true)
        XCTAssertEqual(result.formattedText, "4111 1111 1111 1111")
    }
    
    func testAddAndFormatRegex() {
        
        let textField = FormatTextField()
        textField.formatPattern = "#### #### #### ####"
        let str = "4111111111111111"
        textField.addAndFormatText(str)
        XCTAssertEqual(textField.secureText, "4111 1111 1111 1111")
    }
    func testConstructV2RequestBody() {
        let result = FlowVaultInsertRequestBody.createRequestBody(vaultID: "vault123", records: ["records": [["table": "table", "fields": ["field1": "value1"]]]], options: FlowVaultICOptions(tokens: true))
        XCTAssertEqual(result["vaultID"] as! String, "vault123")
        let records = result["records"] as! [[String: Any]]
        XCTAssertEqual(records[0]["tableName"] as! String, "table")
        XCTAssertEqual(records[0]["data"] as! [String: String], ["field1": "value1"])
    }

    func testConstructV2RequestBodyWithUpsert() {
        let upsert = [UpsertOption(table: "table", uniqueColumns: ["field1"], updateType: .REPLACE)]
        let result = FlowVaultInsertRequestBody.createRequestBody(vaultID: "vault123", records: ["records": [["table": "table", "fields": ["field1": "value1"]]]], options: FlowVaultICOptions(tokens: true, upsert: upsert))
        let records = result["records"] as! [[String: Any]]
        let upsertPayload = records[0]["upsert"] as! [String: Any]
        XCTAssertEqual(upsertPayload["uniqueColumns"] as! [String], ["field1"])
        XCTAssertEqual(upsertPayload["updateType"] as! String, "REPLACE")
    }

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

    func testFlowVaultUpdateRequestBody() {
        let records: [[String: Any]] = [
            ["skyflowID": "id1", "tableName": "table1", "data": ["email": "a@b.com"]],
            ["skyflowID": "id2", "tableName": "table2", "data": ["name": "chiku"]]
        ]

        let result = FlowVaultUpdateRequestBody.createRequestBody(vaultID: "vault123", records: records)

        XCTAssertEqual(result["vaultID"] as? String, "vault123")
        let resultRecords = result["records"] as! [[String: Any]]
        XCTAssertEqual(resultRecords.count, 2)
        XCTAssertEqual(resultRecords[0]["skyflowID"] as? String, "id1")
        XCTAssertEqual(resultRecords[0]["tableName"] as? String, "table1")
        XCTAssertEqual(resultRecords[1]["tableName"] as? String, "table2")
    }
}
