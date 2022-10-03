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
            XCTAssertEqual((error as! NSError).code, ErrorCodes.REGEX_MATCH_FAILED(value: "9$").code)
            XCTAssert((error as NSError).localizedDescription.contains( ErrorCodes.REGEX_MATCH_FAILED(value: "9$").description))
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
    
    func testConstructRequestWithTokens() {
        let apiClient = APIClient(vaultID: "", vaultURL: "", tokenProvider: DemoTokenProvider())
        let result = apiClient.constructBatchRequestBody(records: ["records": [["table": "table", "fields": ["field1": "value1"]]]], options: ICOptions(tokens: true))
        let record = result["records"] as! [[String: Any]]
        let id = record[1]["ID"] as! String
        let tokenization = record[1]["tokenization"] as! Bool
        XCTAssertEqual(id, "$responses.0.records.0.skyflow_id")
        XCTAssertTrue(tokenization)
    }
}


