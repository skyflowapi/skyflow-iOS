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
//        self.skyflow = Client(Configuration(vaultID: "ffe21f44f68a4ae3b4fe55ee7f0a85d6", vaultURL: "https://na1.area51.vault.skyflowapis.com/", tokenProvider: DemoTokenProvider()))
//        self.revealTestId = "6255-9119-4502-5915"
        self.skyflow = Client(Configuration(vaultID: "bdc271aee8584eed88253877019657b3", vaultURL: "https://sb.area51.vault.skyflowapis.dev", tokenProvider: DemoTokenProvider()))
        self.revealTestId = "1815-6223-1073-1425"
    }

    override func tearDown() {
        skyflow = nil
    }

    func getRevealElementInput() -> RevealElementInput {
        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        let styles = Styles(base: bstyle)

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

//    func testPureGet() {
//        let defaultRecords = ["records": [["token": revealTestId, "redaction": RedactionType.DEFAULT]]]
//        let responseData = getDataFromClientWithExpectation(description: "Pure Get call",records: defaultRecords)
//        let jsonData = try! JSONSerialization.jsonObject(with: responseData, options: []) as! [String: Any]
//
//        let responseEntries = jsonData["records"] as! [Any]
//        let count = responseEntries.count
//        let onlyEntry = responseEntries[0] as? [String: Any]
//
//        XCTAssertNotNil(jsonData)
//        XCTAssertEqual(count, 1)
//        XCTAssertNotNil((onlyEntry?["fields"] as! [String: String])["cardNumber"])
//        XCTAssertEqual((onlyEntry?["fields"] as! [String: String])["cardNumber"], "1232132132311231")
//        XCTAssertEqual(onlyEntry?["token"] as? String, revealTestId)
//    }

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
        XCTAssertEqual(onlyEntry?["value"] as? String, "4111111111111111")
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

        let revealedOutput = "4111111111111111"
        
        window.addSubview(revealElement!)
        
        let expectation = XCTestExpectation(description: "Should return reveal output")
        let callback = DemoAPICallback(expectation: expectation)

        revealContainer?.reveal(callback: callback)

        wait(for: [expectation], timeout: 30.0)
        
        XCTAssertEqual(revealElement?.skyflowLabelView.label.secureText, revealedOutput)
    }

    func testGetWithoutURLTrailingSlash() {
        let noTrailingSlashSkyflow = Client(Configuration(vaultID: "bdc271aee8584eed88253877019657b3", vaultURL: "https://sb.area51.vault.skyflowapis.dev/", tokenProvider: DemoTokenProvider()))
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
        let noTrailingSlashSkyflow = Client(Configuration(vaultID: "ffe21f44f68a4ae3b4fe55ee7f0a85d6", vaultURL: "https://na2.area51.vault.skyflowapis.com/", tokenProvider: DemoTokenProvider()))
        let defaultRecords = ["records": [["token": revealTestId]]]

        let expectRecords = XCTestExpectation(description: "Should get errors")
        let callback = DemoAPICallback(expectation: expectRecords)
        noTrailingSlashSkyflow.detokenize(records: defaultRecords, callback: callback)

        wait(for: [expectRecords], timeout: 10.0)

        let responseData = (callback.data["errors"] as! [Any])[0] as? [String: Any]
        XCTAssertEqual((responseData?["error"] as? Error)?.localizedDescription, "A server with the specified hostname could not be found.")
    }

    func testWithInvalidVaultID() {
        let noTrailingSlashSkyflow = Client(Configuration(vaultID: "invalid-vault-id", vaultURL: "https://sb.area51.vault.skyflowapis.dev", tokenProvider: DemoTokenProvider()))
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
        XCTAssertEqual((((errors[0] as! [String: Any])["error"]) as! NSError).code, 500)
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
        
        let skyflow = Client(Configuration(vaultID: "bdc271aee8584eed88253877019657b3", vaultURL: "https://sb.area51.vault.skyflowapis.dev", tokenProvider: InvalidTokenProvider()))
        let revealTestId = "1815-6223-1073-1425"
        
        let defaultRecords = ["records": [["token": revealTestId]]]
        
        let expectRecords = XCTestExpectation(description: description)
        let callback = DemoAPICallback(expectation: expectRecords)
        skyflow.detokenize(records: defaultRecords, callback: callback)

        wait(for: [expectRecords], timeout: 10.0)
        
        let errorEntry = (callback.data["errors"] as? [Any])?[0]
        
        let errorMessage = ((errorEntry as? [String: Any])?["error"] as? Error)?.localizedDescription
        
        XCTAssertNotNil("notnil")
        XCTAssertEqual(errorMessage, "TokenProvider error")

    }
    
}
