/*
 * Copyright (c) 2022 Skyflow
*/

import XCTest
@testable import SkyflowFlowVault
@testable import SkyflowCore

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
        let result = CollectRequestBuilder.createInsertRequestBody(vaultID: "vault123", records: ["records": [["table": "table", "fields": ["field1": "value1"]]]], upsert: nil)
        XCTAssertEqual(result["vaultID"] as! String, "vault123")
        let records = result["records"] as! [[String: Any]]
        XCTAssertEqual(records[0]["tableName"] as! String, "table")
        XCTAssertEqual(records[0]["data"] as! [String: String], ["field1": "value1"])
    }

    func testConstructV2RequestBodyWithUpsert() {
        let upsert = [UpsertOption(tableName: "table", uniqueColumns: ["field1"], updateType: .REPLACE)]
        let result = CollectRequestBuilder.createInsertRequestBody(vaultID: "vault123", records: ["records": [["table": "table", "fields": ["field1": "value1"]]]], upsert: upsert)
        let records = result["records"] as! [[String: Any]]
        let upsertPayload = records[0]["upsert"] as! [String: Any]
        XCTAssertEqual(upsertPayload["uniqueColumns"] as! [String], ["field1"])
        XCTAssertEqual(upsertPayload["updateType"] as! String, "REPLACE")
    }

    // Not exercised by any current call site (UpsertOption always supplies a concrete
    // updateType today), but the nil default is part of the public API - confirms
    // "updateType" is omitted from the wire payload rather than serialized as null.
    func testConstructV2RequestBodyWithUpsertAndNilUpdateType() {
        let upsert = [UpsertOption(tableName: "table", uniqueColumns: ["field1"])]
        let result = CollectRequestBuilder.createInsertRequestBody(vaultID: "vault123", records: ["records": [["table": "table", "fields": ["field1": "value1"]]]], upsert: upsert)
        let records = result["records"] as! [[String: Any]]
        let upsertPayload = records[0]["upsert"] as! [String: Any]
        XCTAssertEqual(upsertPayload["uniqueColumns"] as! [String], ["field1"])
        XCTAssertNil(upsertPayload["updateType"])
    }


    func testCreateUpdateRequestBody() {
        let records: [[String: Any]] = [
            ["skyflowID": "id1", "tableName": "table1", "data": ["email": "a@b.com"]],
            ["skyflowID": "id2", "tableName": "table2", "data": ["name": "chiku"]]
        ]

        let result = CollectRequestBuilder.createUpdateRequestBody(vaultID: "vault123", records: records)

        XCTAssertEqual(result["vaultID"] as? String, "vault123")
        let resultRecords = result["records"] as! [[String: Any]]
        XCTAssertEqual(resultRecords.count, 2)
        XCTAssertEqual(resultRecords[0]["skyflowID"] as? String, "id1")
        XCTAssertEqual(resultRecords[0]["tableName"] as? String, "table1")
        XCTAssertEqual(resultRecords[1]["tableName"] as? String, "table2")
    }
}
