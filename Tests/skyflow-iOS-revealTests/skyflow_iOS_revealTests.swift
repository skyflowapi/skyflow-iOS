/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation
import XCTest
import AEXML
@testable import Skyflow

// swiftlint:disable:next type_body_length
class skyflow_iOS_revealTests: XCTestCase {
    var skyflow: Client!
    var revealTestId: String!

    override func setUp() {
        self.skyflow = Client(Configuration(
                                vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!,
                                vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!,
                                tokenProvider: DemoTokenProvider(), options: Options(logLevel: .DEBUG)))
        self.revealTestId = ProcessInfo.processInfo.environment["DETOKENIZE_TEST_TOKEN"]!
    }

    override func tearDown() {
        skyflow = nil
    }
    
    func waitForUIUpdates() {
        
        let expectation = self.expectation(description: "Test")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }

    func getRevealElementInput() -> RevealElementInput {
        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        let istyle = Style(textColor: .red)
        let styles = Styles(base: bstyle, invalid: istyle)

        let revealElementInput = RevealElementInput(token: revealTestId, inputStyles: styles, label: "RevealElement", redaction: .DEFAULT)

        return revealElementInput
    }

    func getDataFromClientWithExpectation(description: String = "should get records", records: [String: Any]) -> Data {
        let expectRecords = XCTestExpectation(description: description)
        let callback = DemoAPICallback(expectation: expectRecords)
        skyflow.detokenize(records: records, callback: callback)

        wait(for: [expectRecords], timeout: 10.0)
        return Data(callback.receivedResponse.utf8)
    }

    func testRevealElementInput() {
        let revealElementInput = getRevealElementInput()

        XCTAssertEqual(revealElementInput.token, revealTestId)
        XCTAssertEqual(revealElementInput.redaction, .DEFAULT)
        XCTAssertEqual(revealElementInput.label, "RevealElement")
    }

    func testCreateSkyflowRevealContainer() {
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let revealElementInput = getRevealElementInput()
        let revealElement = revealContainer?.create(input: revealElementInput)

        let labelView = revealElement!.skyflowLabelView
        let labelField = revealElement!.labelField

        XCTAssertEqual(labelView!.borderColor, .blue)
        XCTAssertEqual(labelView!.cornerRadius, 20)
        XCTAssertEqual(labelView!.padding, UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5))
        XCTAssertEqual(labelView!.textColor, .blue)
        XCTAssertEqual(labelView!.label.secureText, revealTestId)
        XCTAssertEqual(labelField.text, revealElementInput.label)
    }

    func testCheckRevealElementsArray() {
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let revealElementInput = getRevealElementInput()
        _ = revealContainer?.create(input: revealElementInput)


        XCTAssertEqual(revealContainer?.revealElements.count, 1)
        XCTAssertNotNil(revealContainer?.revealElements[0].labelField)
    }

    
    func testCreateRevealRequestBody() {
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let revealElementInput = getRevealElementInput()
        let revealElement = revealContainer?.create(input: revealElementInput)
        
        let requestBody = RevealRequestBody.createRequestBody(elements: [revealElement!]) as! [String: [[String: String]]]
        
        let result: [String: [[String: String]]] = ["records": [["token": revealTestId]]]
        
        XCTAssertEqual(result, requestBody)
    }
    
    func testDetokenizeInvalidToken() {
        
        class InvalidTokenProvider: TokenProvider {
            func getBearerToken(_ apiCallback: Callback) {
                apiCallback.onFailure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "TokenProvider error"]))
            }
        }
        
        let skyflow = Client(
            Configuration(vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!,
                          vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!,
                          tokenProvider: InvalidTokenProvider()))
        
        let defaultRecords = ["records": [["token": self.revealTestId]]]
        
        let expectRecords = XCTestExpectation(description: description)
        let callback = DemoAPICallback(expectation: expectRecords)
        skyflow.detokenize(records: defaultRecords, callback: callback)

        wait(for: [expectRecords], timeout: 10.0)
        
        let errorEntry = (callback.data["errors"] as? [Any])?[0]
        
        let errorMessage = ((errorEntry as? [String: Any])?["error"] as? Error)?.localizedDescription

        XCTAssertEqual(errorMessage, "TokenProvider error")

    }
    
    
    func testSetError() {
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        var revealElementInput = getRevealElementInput()
        let revealElement = revealContainer?.create(input: revealElementInput)
        let errorMessage = "Triggered Error"
        
        revealElement!.setError(errorMessage)
        
        XCTAssertEqual(revealElement?.errorMessage.alpha, 1.0)
        XCTAssertEqual(revealElement?.errorMessage.text, errorMessage)
        XCTAssertEqual(revealElement?.skyflowLabelView.textColor, .red)
        
    }
    
    func testSetErrorOnReveal() {
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        var revealElementInput = getRevealElementInput()
        revealElementInput.token = "invalidtoken"
        let revealElement = revealContainer?.create(input: revealElementInput)
        let errorMessage = "Triggered Error"
        
        revealElement!.setError(errorMessage)
        
        let expectFailure = XCTestExpectation(description: "Should fail with triggered error message")
        
        let window = UIWindow()
        window.addSubview(revealElement!)
        
        let callback = DemoAPICallback(expectation: expectFailure)
        revealContainer?.reveal(callback: callback)
        
        wait(for: [expectFailure], timeout: 10.0)
        
        XCTAssertEqual(callback.receivedResponse, "Interface: reveal container - \(errorMessage)")
        
    }
    
    func testResetError() {
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        var revealElementInput = getRevealElementInput()
        let revealElement = revealContainer?.create(input: revealElementInput)
        let errorMessage = "Triggered Error"
        
        revealElement!.setError(errorMessage)
        revealElement!.resetError()
        
        XCTAssertEqual(revealElement?.errorMessage.alpha, 0.0)
    }
    
    func testGetID() {
        let collectContainer = skyflow.container(type: ContainerType.COLLECT)
        let revealContainer = skyflow.container(type: ContainerType.REVEAL)
        let collectElementInput = CollectElementInput(type: .PIN)
        let collectElement = collectContainer?.create(input: collectElementInput)
        let revealElementInput = RevealElementInput(label: "")
        let revealElement = revealContainer?.create(input: revealElementInput)
        
        let collectID = collectElement?.getID()
        let revealID = revealElement?.getID()

        XCTAssertNotEqual(collectID, "")
        XCTAssertNotEqual(revealID, "")
    }
}
