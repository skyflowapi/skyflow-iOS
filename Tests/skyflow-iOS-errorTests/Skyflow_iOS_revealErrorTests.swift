//
//  Skyflow_iOS_revealErrorTests.swift
//  skyflow-iOS-revealTests
//
//  Created by Tejesh Reddy Allampati on 08/10/21.
//

import Foundation
import XCTest
@testable import Skyflow

// swiftlint:disable:next type_body_length
class Skyflow_iOS_revealErrorTests: XCTestCase {
    var skyflow: Client!
    var revealTestId: String!

    override func setUp() {
        self.skyflow = Client(Configuration(vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!, vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!, tokenProvider: DemoTokenProvider()))
        self.revealTestId = "6255-9119-4502-5915"
    }

    override func tearDown() {
        skyflow = nil
    }

    func getDataFromClientWithExpectation(description: String = "should get records", records: [String: Any]) -> String {
        let expectRecords = XCTestExpectation(description: description)
        let callback = DemoAPICallback(expectation: expectRecords)
        skyflow.detokenize(records: records, callback: callback)

        wait(for: [expectRecords], timeout: 10.0)
        if callback.receivedResponse.isEmpty {
            if callback.data["errors"] != nil {
                return (callback.data["errors"] as! [NSError])[0].localizedDescription
            } else {
                return "ok"
            }
        } else {
            return callback.receivedResponse
        }
    }

    func getByIDFromClientWithExpectation(description: String = "should get records", records: [String: Any]) -> String {
        let expectRecords = XCTestExpectation(description: description)
        let callback = DemoAPICallback(expectation: expectRecords)
        skyflow.getById(records: records, callback: callback)

        wait(for: [expectRecords], timeout: 10.0)
        if callback.receivedResponse.isEmpty {
            if callback.data["errors"] != nil {
                return (callback.data["errors"] as! [NSError])[0].localizedDescription
            } else {
                return "ok"
            }
        } else {
            return callback.receivedResponse
        }
    }


    func testDetokenizeNoRecords() {
        let records = ["typo": [["token": revealTestId, "redaction": RedactionType.DEFAULT]]]
        let result = getDataFromClientWithExpectation(records: records)
        XCTAssertEqual(result, "Interface: client detokenize - " + ErrorCodes.RECORDS_KEY_ERROR().description)
    }

    func testDetokenizeBadRecords() {
        let records = ["records": 123]
        let result = getDataFromClientWithExpectation(records: records)
        XCTAssertEqual(result, "Interface: client detokenize - " + ErrorCodes.INVALID_RECORDS_TYPE().description)
    }
    
    func testDetokenizeEmptyRecords() {
        let records = ["records": []]
        let result = getDataFromClientWithExpectation(records: records)
        XCTAssertEqual(result, "Interface: client detokenize - " + ErrorCodes.EMPTY_RECORDS_OBJECT().description)
    }

    func testDetokenizeNoTokens() {
        let records = ["records": [["redaction": RedactionType.DEFAULT]]]
        let result = getDataFromClientWithExpectation(records: records)
        XCTAssertEqual(result, "Interface: client detokenize - " + ErrorCodes.ID_KEY_ERROR().description)
    }

    func testDetokenizeBadTokens() {
        let records = ["records": [["token": [], "redaction": RedactionType.DEFAULT]]]
        let result = getDataFromClientWithExpectation(records: records)
        XCTAssertEqual(result, "Interface: client detokenize - " + ErrorCodes.INVALID_TOKEN_TYPE().description)
    }

    func testContainerRevealWithUnmountedElements() {
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)

        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        let styles = Styles(base: bstyle)

        let revealElementInput = RevealElementInput(token: revealTestId, inputStyles: styles, label: "RevealElement")
        let revealElement = revealContainer?.create(input: revealElementInput, options: RevealElementOptions())

        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Should return reveal output"))
        revealContainer?.reveal(callback: callback)

        let result = callback.receivedResponse

        XCTAssertEqual(result, "Interface: reveal container - " + ErrorCodes.UNMOUNTED_REVEAL_ELEMENT(value: revealTestId).description)
    }

    func testContainerRevealWithEmptyToken() {
        let window = UIWindow()
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)

        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        let styles = Styles(base: bstyle)

        let revealElementInput = RevealElementInput(inputStyles: styles, label: "RevealElement", redaction: .DEFAULT)
        let revealElement = revealContainer?.create(input: revealElementInput, options: RevealElementOptions())

        window.addSubview(revealElement!)

        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Should return reveal output"))
        revealContainer?.reveal(callback: callback)

        let result = callback.receivedResponse

        XCTAssertEqual(result, "Interface: reveal container - " + ErrorCodes.EMPTY_TOKEN_ID().description)
    }

    func testGetByIdNoRecords() {
        let records = ["ok": [["redaction": RedactionType.DEFAULT]]]
        let result = getByIDFromClientWithExpectation(records: records)
        XCTAssertEqual(result, "Interface: client getById - " + ErrorCodes.EMPTY_RECORDS_OBJECT().description)
    }

    func testGetByIdInvalidRecords() {
        let records = ["records": 12]
        let result = getByIDFromClientWithExpectation(records: records)
        XCTAssertEqual(result, "Interface: client getById - " + ErrorCodes.INVALID_RECORDS_TYPE().description)
    }

    func testGetByIdNoIds() {
        let records = ["records": [["redaction": RedactionType.DEFAULT]]]
        let result = getByIDFromClientWithExpectation(records: records)
        XCTAssertEqual(result, "Interface: client getById - " + ErrorCodes.MISSING_KEY_IDS().description)
    }

    func testGetByIdInvalidIds() {
        let records = ["records": [["ids": RedactionType.DEFAULT]]]
        let result = getByIDFromClientWithExpectation(records: records)
        XCTAssertEqual(result, "Interface: client getById - " + ErrorCodes.INVALID_IDS_TYPE().description)
    }

    func testGetByIdNoTable() {
        let records = ["records": [["ids": ["abc"]]]]
        let result = getByIDFromClientWithExpectation(records: records)
        XCTAssertEqual(result, "Interface: client getById - " + ErrorCodes.TABLE_KEY_ERROR().description)
    }

    func testGetByIdInvalidTable() {
        let records = ["records": [["ids": ["abc"], "table": ["abc"]]]]
        let result = getByIDFromClientWithExpectation(records: records)
        XCTAssertEqual(result, "Interface: client getById - " + ErrorCodes.INVALID_TABLE_NAME_TYPE().description)
    }

    func testGetByIdNoRedaction() {
        let records = ["records": [["ids": ["abc"], "table": "table"]]]
        let result = getByIDFromClientWithExpectation(records: records)
        XCTAssertEqual(result, "Interface: client getById - " + ErrorCodes.REDACTION_KEY_ERROR().description)
    }

    func testGetByIdInvalidRedaction() {
        let records = ["records": [["ids": ["abc"], "table": "table", "redaction": "DEFAULT"]]]
        let result = getByIDFromClientWithExpectation(records: records)
        XCTAssertEqual(result, "Interface: client getById - " + ErrorCodes.INVALID_REDACTION_TYPE(value: "DEFAULT").description)
    }
}
