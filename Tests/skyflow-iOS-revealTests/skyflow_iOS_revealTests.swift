//
//  File.swift
//  
//
//  Created by Tejesh Reddy Allampati on 04/10/21.
//

import Foundation
import XCTest
@testable import Skyflow


class skyflow_iOS_revealTests: XCTestCase {
    var skyflow: Client!
    var revealTestId: String!

    override func setUp() {
        self.skyflow = Client(Configuration(vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!, vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!, tokenProvider: DemoTokenProvider()))
        self.revealTestId = ProcessInfo.processInfo.environment["DETOKENIZE_TEST_TOKEN"]!
    }

    override func tearDown() {
        skyflow = nil
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
        let revealElement = revealContainer?.create(input: revealElementInput, options: RevealElementOptions())

        let labelView = revealElement!.skyflowLabelView
        let labelField = revealElement!.labelField

        XCTAssertEqual(labelView!.borderColor, .blue)
        XCTAssertEqual(labelView!.cornerRadius, 20)
        XCTAssertEqual(labelView!.padding, UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5))
        XCTAssertEqual(labelView!.textColor, .blue)
        XCTAssertEqual(labelView!.label.secureText, revealTestId)
        XCTAssertEqual(labelField.text, revealElementInput.label)
    }

    func testNewDetokenize() {
        let defaultRecords = ["records": [["token": revealTestId!]]]

        let responseData = getDataFromClientWithExpectation(description: "New detokenize call", records: defaultRecords)
        let jsonData = try! JSONSerialization.jsonObject(with: responseData, options: []) as! [String: Any]

        let responseEntries = jsonData["records"] as! [Any]
        let count = responseEntries.count
        let onlyEntry = responseEntries[0] as? [String: Any]

        XCTAssertNotNil(jsonData)
        XCTAssertEqual(count, 1)
        XCTAssertEqual(onlyEntry?["token"] as? String, revealTestId)
        XCTAssertEqual(onlyEntry?["value"] as? String, ProcessInfo.processInfo.environment["DETOKENIZE_TEST_VALUE"]!)
    }

    func testGetWithInvalidToken() {
        let defaultRecords = ["records": [["token": "abc"]]]

        let expectRecords = XCTestExpectation(description: description)
        let callback = DemoAPICallback(expectation: expectRecords)
        skyflow.detokenize(records: defaultRecords, callback: callback)

        wait(for: [expectRecords], timeout: 10.0)
        let jsonData = callback.data

        XCTAssertNotNil(jsonData)
        XCTAssertNotNil(jsonData["errors"])

        let error = (jsonData["errors"] as! [[String: Any]])[0]["error"]
        XCTAssertNotNil(error)
        XCTAssertEqual((error as! NSError).code, 404)
    }

    func testCheckRevealElementsArray() {
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let revealElementInput = getRevealElementInput()
        _ = revealContainer?.create(input: revealElementInput, options: RevealElementOptions())


        XCTAssertEqual(revealContainer?.revealElements.count, 1)
        XCTAssertNotNil(revealContainer?.revealElements[0].labelField)
    }

    func testRevealContainersReveal() {
        // Invalid test
        let window = UIWindow()
        
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let revealElementInput = getRevealElementInput()
        let revealElement = revealContainer?.create(input: revealElementInput, options: RevealElementOptions())

        let revealedOutput = ProcessInfo.processInfo.environment["DETOKENIZE_TEST_VALUE"]!
        
        window.addSubview(revealElement!)
        
        let expectation = XCTestExpectation(description: "Should return reveal output")
        let callback = DemoAPICallback(expectation: expectation)

        revealContainer?.reveal(callback: callback)

        wait(for: [expectation], timeout: 30.0)
        
        XCTAssertEqual(revealElement?.skyflowLabelView.label.secureText, revealedOutput)
        XCTAssertEqual(revealElement?.getValue(), revealedOutput)
    }

    func testGetWithURLTrailingSlash() {
        let noTrailingSlashSkyflow = Client(Configuration(vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!,
                                                          vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]! + "/",
                                                          tokenProvider: DemoTokenProvider()))
        let defaultRecords = ["records": [["token": revealTestId]]]

        let expectRecords = XCTestExpectation(description: "Should get errors")
        let callback = DemoAPICallback(expectation: expectRecords)
        noTrailingSlashSkyflow.detokenize(records: defaultRecords, callback: callback)

        wait(for: [expectRecords], timeout: 10.0)
        let responseData = Data(callback.receivedResponse.utf8)

        let jsonData = try! JSONSerialization.jsonObject(with: responseData, options: []) as! [String: Any]

        let responseEntries = jsonData["records"] as! [Any]
        let count = responseEntries.count

        XCTAssertNotNil(jsonData)
        XCTAssertEqual(count, 1)
    }

    func testWithWrongVaultURL() {
        let noTrailingSlashSkyflow = Client(Configuration(vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!, vaultURL: "https://dummy.area51.vault.skyflowapis.com/", tokenProvider: DemoTokenProvider()))
        let defaultRecords = ["records": [["token": revealTestId]]]

        let expectRecords = XCTestExpectation(description: "Should get errors")
        let callback = DemoAPICallback(expectation: expectRecords)
        noTrailingSlashSkyflow.detokenize(records: defaultRecords, callback: callback)

        wait(for: [expectRecords], timeout: 10.0)

        let responseData = (callback.data["errors"] as! [Any])[0] as? [String: Any]
        XCTAssertEqual((responseData?["error"] as? Error)?.localizedDescription, "A server with the specified hostname could not be found.")
    }

    func testWithInvalidVaultID() {
        let noTrailingSlashSkyflow = Client(Configuration(vaultID: "invalid-vault-id", vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!, tokenProvider: DemoTokenProvider()))
        let defaultRecords = ["records": [["token": revealTestId]]]

        let expectRecords = XCTestExpectation(description: "Should get errors")
        let callback = DemoAPICallback(expectation: expectRecords)
        noTrailingSlashSkyflow.detokenize(records: defaultRecords, callback: callback)

        wait(for: [expectRecords], timeout: 10.0)

        let jsonData = callback.data

        let errors = jsonData["errors"] as! [Any]
        let errorCount = errors.count

        XCTAssertNotNil(jsonData)
        XCTAssertEqual(errorCount, 1)
        XCTAssertEqual((((errors[0] as! [String: Any])["error"]) as! NSError).code, 404)
    }
    
    func testCreateRevealRequestBody() {
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let revealElementInput = getRevealElementInput()
        let revealElement = revealContainer?.create(input: revealElementInput, options: RevealElementOptions())
        
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
    
    func testContainerRevealInvalidTokens() {
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        var revealElementInput = getRevealElementInput()
        var revealElementValidInput = getRevealElementInput()
        revealElementInput.token = "invalidtoken"
        revealElementValidInput.token = revealTestId
        let revealElement = revealContainer?.create(input: revealElementInput, options: RevealElementOptions())
        let validRevealElement = revealContainer?.create(input: revealElementValidInput, options: RevealElementOptions())
        
        let window = UIWindow()
        window.addSubview(revealElement!)
        window.addSubview(validRevealElement!)
        
        let expectation = XCTestExpectation(description: "Should be on failure")
        let callback = DemoAPICallback(expectation: expectation)
        revealContainer?.reveal(callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        
        print("=====", callback.data)
        
        XCTAssertNotNil(callback.data["errors"])
        XCTAssertNotNil(callback.data["records"])
        let errors = callback.data["errors"] as! [[String: Any]]
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual((errors[0]["error"] as! NSError).code, 404)
        XCTAssertEqual(errors[0]["token"] as! String, "invalidtoken")
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
        revealElementInput.token = "invalidtoken"
        let revealElement = revealContainer?.create(input: revealElementInput, options: RevealElementOptions())
        let errorMessage = "Triggered Error"
        
        revealElement!.setError(errorMessage)
        
        let expectFailure = XCTestExpectation(description: "Should fail with triggered error message")
        
        let window = UIWindow()
        window.addSubview(revealElement!)
        
        let callback = DemoAPICallback(expectation: expectFailure)
        revealContainer?.reveal(callback: callback)
        
        wait(for: [expectFailure], timeout: 10.0)
        
        XCTAssertEqual(callback.receivedResponse, errorMessage)
        
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
}
