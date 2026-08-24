/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation
import XCTest

@testable import SkyflowFlowVault
@testable import SkyflowCore

// swiftlint:disable:next type_body_length
class skyflow_iOS_revealTests: XCTestCase {
    var skyflow: Client!
    var revealTestId: String!

    override func setUp() {
        self.skyflow = Client(Configuration(
                                vaultID: (ProcessInfo.processInfo.environment["VAULT_ID"] ?? "dummy_vault_id"),
                                vaultURL: (ProcessInfo.processInfo.environment["VAULT_URL"] ?? "https://dummy.vault.skyflowapis.dev/"),
                                tokenProvider: DemoTokenProvider(), options: Options(logLevel: .DEBUG)))
        self.revealTestId = (ProcessInfo.processInfo.environment["DETOKENIZE_TEST_TOKEN"] ?? "dummy_detokenize_token")
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

        let revealElementInput = RevealElementInput(token: revealTestId, inputStyles: styles, label: "RevealElement")

        return revealElementInput
    }

    func testRevealElementInput() {
        let revealElementInput = getRevealElementInput()

        XCTAssertEqual(revealElementInput.data.token, revealTestId)
        XCTAssertEqual(revealElementInput.data.label, "RevealElement")
    }

    func testRevealOptionsCarriesTokenGroupRedactions() {
        let options = RevealOptions(tokenGroupRedactions: [TokenGroupRedaction(tokenGroupName: "deterministic_string", redaction: "MASKED")])

        XCTAssertEqual(options.tokenGroupRedactions?.count, 1)
        XCTAssertEqual(options.tokenGroupRedactions?.first?.tokenGroupName, "deterministic_string")
        XCTAssertEqual(options.tokenGroupRedactions?.first?.redaction, "MASKED")
    }

    func testRevealOptionsDefaultsToNilTokenGroupRedactions() {
        let options = RevealOptions()

        XCTAssertNil(options.tokenGroupRedactions)
    }

    func testCreateSkyflowRevealContainer() {
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let revealElementInput = getRevealElementInput()
        let revealElement = revealContainer?.create(input: revealElementInput, options: RevealElementOptions())

        let labelView = revealElement!.skyflowLabelView
        let labelField = revealElement!.labelField

        XCTAssertEqual(labelView!.borderColor, .blue)
        XCTAssertEqual(labelView!.cornerRadius, 20)
        XCTAssertEqual(labelView!.padding, UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5))
        XCTAssertEqual(labelView!.textColor, .blue)
        XCTAssertEqual(labelView!.label.secureText, revealTestId)
        XCTAssertEqual(labelField.text, revealElementInput.data.label)
    }

    func testCheckRevealElementsArray() {
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let revealElementInput = getRevealElementInput()
        _ = revealContainer?.create(input: revealElementInput, options: RevealElementOptions())


        XCTAssertEqual(revealContainer?.revealElements.count, 1)
        XCTAssertNotNil(revealContainer?.revealElements[0].labelField)
    }
    func compareDictionaries(dict1: [String: Any], dict2: [String: Any]) -> Bool {
        let nsDict1 = dict1 as NSDictionary
        let nsDict2 = dict2 as NSDictionary
        return nsDict1.isEqual(to: nsDict2 as! [AnyHashable : Any])
    }
    
    func testCreateRevealRequestBody() {
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let revealElementInput = getRevealElementInput()
        let revealElement = revealContainer?.create(input: revealElementInput, options: RevealElementOptions())

        let requestBody = RevealRequestBuilder.createRevealRecords(elements: [revealElement!]) as! [String: [[String: Any]]]

        let result: [String: [[String: Any]]] = ["records": [["token": revealTestId]]]

        XCTAssertTrue(compareDictionaries(dict1: result, dict2: requestBody))
    }
    
    func testSetError() {
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        var revealElementInput = getRevealElementInput()
        let revealElement = revealContainer?.create(input: revealElementInput, options: RevealElementOptions())
        let errorMessage = "Triggered Error"
        
        revealElement!.setError(errorMessage)
        
        XCTAssertEqual(revealElement?.errorMessage.alpha, 1.0)
        XCTAssertEqual(revealElement?.errorMessage.text, errorMessage)
        XCTAssertEqual(revealElement?.skyflowLabelView.textColor, .red)
        
    }
    
    func testSetErrorOnReveal() {
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        var revealElementInput = getRevealElementInput()
        revealElementInput.data.token = "invalidtoken"
        let revealElement = revealContainer?.create(input: revealElementInput, options: RevealElementOptions())
        let errorMessage = "Triggered Error"
        
        revealElement!.setError(errorMessage)
        
        let expectFailure = XCTestExpectation(description: "Should fail with triggered error message")
        
        let window = UIWindow()
        window.addSubview(revealElement!)
        
        let callback = DemoAPICallback(expectation: expectFailure)
        revealContainer?.reveal(callback: callback.asRevealCallback)
        
        wait(for: [expectFailure], timeout: 10.0)
        
        XCTAssertEqual(callback.receivedResponse, "\(errorMessage)")
        
    }
    
    func testResetError() {
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        var revealElementInput = getRevealElementInput()
        let revealElement = revealContainer?.create(input: revealElementInput, options: RevealElementOptions())
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
