//
//  Skyflow_iOS_revealErrorTests.swift
//  skyflow-iOS-revealTests
//
//  Created by Tejesh Reddy Allampati on 08/10/21.
//

import Foundation
import XCTest
@testable import Skyflow

class Skyflow_iOS_revealErrorTests: XCTestCase {
    var skyflow: Client!
    var revealTestId: String!

    override func setUp() {
        self.skyflow = Client(Configuration(vaultID: "ffe21f44f68a4ae3b4fe55ee7f0a85d6", vaultURL: "https://na1.area51.vault.skyflowapis.com/", tokenProvider: DemoTokenProvider()))
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
        return callback.receivedResponse
    }
    
    
    func testDetokenizeNoRecords() {
        let records = ["typo": [["token": revealTestId, "redaction": RedactionType.DEFAULT]]]
        let result = getDataFromClientWithExpectation(records: records)
        XCTAssertEqual(result, ErrorCodes.RECORDS_KEY_ERROR().description)
    }
    
    func testDetokenizeBadRecords() {
        let records = ["records": 123]
        let result = getDataFromClientWithExpectation(records: records)
        XCTAssertEqual(result, ErrorCodes.INVALID_RECORDS_TYPE().description)
    }
    
    func testDetokenizeNoTokens() {
        let records = ["records": [["redaction": RedactionType.DEFAULT]]]
        let result = getDataFromClientWithExpectation(records: records)
        XCTAssertEqual(result, ErrorCodes.ID_KEY_ERROR().description)
    }
    
    func testDetokenizeBadTokens() {
        let records = ["records": [["token": [], "redaction": RedactionType.DEFAULT]]]
        let result = getDataFromClientWithExpectation(records: records)
        XCTAssertEqual(result, ErrorCodes.INVALID_TOKEN_TYPE().description)
    }
    
    func testDetokenizeNoRedaction() {
        let records = ["records": [["token": []]]]
        let result = getDataFromClientWithExpectation(records: records)
        XCTAssertEqual(result, ErrorCodes.REDACTION_KEY_ERROR().description)
    }
    
    func testDetokenizeInvalidRedaction() {
        let records = ["records": [["token": [], "redaction": "abc"]]]
        let result = getDataFromClientWithExpectation(records: records)
        XCTAssertEqual(result, ErrorCodes.INVALID_REDACTION_TYPE(value: "abc").description)
    }
    
    func testContainerRevealWithUnmountedElements() {
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        
        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        let styles = Styles(base: bstyle)

        let revealElementInput = RevealElementInput(token: revealTestId, inputStyles: styles, label: "RevealElement", redaction: .DEFAULT)
        let revealElement = revealContainer?.create(input: revealElementInput, options: RevealElementOptions())

        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Should return reveal output"))
        revealContainer?.reveal(callback: callback)

        let result = callback.receivedResponse
        
        XCTAssertEqual(result, ErrorCodes.UNMOUNTED_REVEAL_ELEMENT(value: revealTestId).description)

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
        
        XCTAssertEqual(result, ErrorCodes.EMPTY_TOKEN_ID().description)

    }
    
    func testContainerRevealWithEmptyRedaction() {
        let window = UIWindow()
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        
        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        let styles = Styles(base: bstyle)

        let revealElementInput = RevealElementInput(token: revealTestId, inputStyles: styles, label: "RevealElement")
        let revealElement = revealContainer?.create(input: revealElementInput, options: RevealElementOptions())
        
        window.addSubview(revealElement!)

        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Should return reveal output"))
        revealContainer?.reveal(callback: callback)

        let result = callback.receivedResponse
        

    }

}
