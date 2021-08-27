//
//  skyflow_iOS_revealTests.swift
//  skyflow-iOS-collectTests
//
//  Created by Tejesh Reddy Allampati on 26/08/21.
//

import XCTest
@testable import Skyflow
//vaultID: ffe21f44f68a4ae3b4fe55ee7f0a85d6
//Url: https://na1.area51.vault.skyflowapis.com/v1/vaults


class skyflow_iOS_revealTests: XCTestCase {

    var skyflow: Client!
    var revealTestId: String!
    
    override func setUp() {
        self.skyflow = Client(Configuration(vaultId: "ffe21f44f68a4ae3b4fe55ee7f0a85d6", vaultURL: "https://na1.area51.vault.skyflowapis.com/v1/vaults/", tokenProvider: DemoTokenProvider()))
        self.revealTestId = "2429-2390-5964-3689"

    }
    
    override func tearDown() {
        skyflow = nil
    }
    
    func getRevealElementInput() -> RevealElementInput {
        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        let styles = Styles(base: bstyle)
        
        let revealElementInput = RevealElementInput(id: revealTestId, styles: styles, label: "RevealElement", redaction: .DEFAULT)
        
        return revealElementInput

    }
    
    func getDataFromClientWithExpectation(description: String = "should get records", records: [String: Any]) -> Data{
        let expectRecords = XCTestExpectation(description: description)
        let callback = DemoAPICallback(expectation: expectRecords)
        skyflow.get(records: records, callback: callback)
        
        wait(for: [expectRecords], timeout: 10.0)
        return Data(callback.receivedResponse.utf8)
    }
    
    func testRevealElementInput() {
        let revealElementInput = getRevealElementInput()
        
        XCTAssertEqual(revealElementInput.id, revealTestId)
        XCTAssertEqual(revealElementInput.redaction, "DEFAULT")
        XCTAssertEqual(revealElementInput.label, "RevealElement")
    }
    
    func testCreateSkyflowRevealContainer() {
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let revealElementInput = getRevealElementInput()
        let revealElement = revealContainer?.create(input: revealElementInput, options: RevealElementOptions());
        
        let labelView = revealElement!.skyflowLabelView
        let labelField = revealElement!.labelField
        
        XCTAssertEqual(labelView!.borderColor, .blue)
        XCTAssertEqual(labelView!.cornerRadius, 20)
        XCTAssertEqual(labelView!.padding, UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5))
        XCTAssertEqual(labelView!.textColor, .blue)
        XCTAssertEqual(labelView!.label.secureText, revealTestId)
        XCTAssertEqual(labelField.text, revealElementInput.label)
    }
    
    func testPureGet() {
        let defaultRecords = ["records": [["id": revealTestId, "redaction": "DEFAULT"]]]
        let responseData = getDataFromClientWithExpectation(records: defaultRecords)
        let jsonData = try! JSONSerialization.jsonObject(with: responseData, options: []) as! [String:Any]

        let responseEntries = jsonData["records"] as! [Any]
        let count = responseEntries.count
        let onlyEntry = responseEntries[0] as? [String: Any]
        
        XCTAssertNotNil(jsonData)
        XCTAssertEqual(count, 1)
        XCTAssertNotNil((onlyEntry?["fields"] as! [String: String])["cardNumber"])
        XCTAssertEqual((onlyEntry?["fields"] as! [String: String])["cardNumber"], "XXXXXXXXXXXX1111")
        XCTAssertEqual(onlyEntry?["id"] as? String, revealTestId)
    }

    func testGetWithInvalidToken() {
        let defaultRecords = ["records": [["id": "abc", "redaction": "DEFAULT"]]]
        let responseData = getDataFromClientWithExpectation(description: "Should get an error", records: defaultRecords)
        let jsonData = try! JSONSerialization.jsonObject(with: responseData, options: []) as! [String:Any]
                
        XCTAssertNotNil(jsonData)
        XCTAssertNotNil(jsonData["errors"])
        
        let error = (jsonData["errors"] as! [[String: Any]])[0]["error"]
        XCTAssertNotNil(error)
        XCTAssertEqual((error as! [String: String])["code"], "404")
    }
    
    func testCheckRevealElementsArray() {
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let revealElementInput = getRevealElementInput()
        let _ = revealContainer?.create(input: revealElementInput, options: RevealElementOptions())
        

        XCTAssertEqual(revealContainer?.revealElements.count, 1)
        XCTAssertNotNil(revealContainer?.revealElements[0].labelField)
    }
    
    func testRevealContainersReveal() {
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let revealElementInput = getRevealElementInput()
        let revealElement = revealContainer?.create(input: revealElementInput, options: RevealElementOptions());
        
        let revealedOutput = "4111-1111-1111-1111"
        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Should return reveal output"))
        
        revealContainer?.reveal(callback: callback)
        
        XCTAssertEqual(revealElement?.skyflowLabelView.label.secureText, revealedOutput)
        
    }
    
    
}

