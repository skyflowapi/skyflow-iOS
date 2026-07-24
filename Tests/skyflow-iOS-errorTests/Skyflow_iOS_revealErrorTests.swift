/*
 * Copyright (c) 2022 Skyflow
*/

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
        self.skyflow = Client(Configuration(
            vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!,
            vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!,
            tokenProvider: DemoTokenProvider(),
            options: Options(logLevel: .DEBUG)))
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

    func testDetokenizeNoRecords() {
        let records = ["typo": [["token": revealTestId]]]
        let result = getDataFromClientWithExpectation(records: records)
        XCTAssertEqual(result,  ErrorCodes.RECORDS_KEY_ERROR().description)
    }

    func testDetokenizeBadRecords() {
        let records = ["records": 123]
        let result = getDataFromClientWithExpectation(records: records)
        XCTAssertEqual(result,  ErrorCodes.INVALID_RECORDS_TYPE().description)
    }

    func testDetokenizeEmptyRecords() {
        let records = ["records": []]
        let result = getDataFromClientWithExpectation(records: records)
        XCTAssertEqual(result,  ErrorCodes.EMPTY_RECORDS_OBJECT().description)
    }

    func testDetokenizeNoTokens() {
        let records = ["records": [["foo": "bar"]]]
        let result = getDataFromClientWithExpectation(records: records)
        XCTAssertEqual(result,  ErrorCodes.ID_KEY_ERROR().description)
    }

    func testDetokenizeBadTokens() {
        let records = ["records": [["token": []]]]
        let result = getDataFromClientWithExpectation(records: records)
        XCTAssertEqual(result,  ErrorCodes.INVALID_TOKEN_TYPE(value: "0").description)
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

        XCTAssertEqual(result, ErrorCodes.UNMOUNTED_REVEAL_ELEMENT(value: revealTestId).description)
    }
    func testContainerRevealWithEmptyToken() {
        let window = UIWindow()
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)

        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        let styles = Styles(base: bstyle)

        let revealElementInput = RevealElementInput(inputStyles: styles, label: "RevealElement")
        let revealElement = revealContainer?.create(input: revealElementInput, options: RevealElementOptions())

        window.addSubview(revealElement!)

        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Should return reveal output"))
        revealContainer?.reveal(callback: callback)

        let result = callback.receivedResponse

        XCTAssertEqual(result,  ErrorCodes.EMPTY_TOKEN_ID().description)
    }

    func testContainerRevealEmptyVaultURL() {
        // Unlike Client.detokenize()/getById()/get(), RevealContainer.reveal() calls
        // callback.onFailure directly with the raw NSError (no callRevealOnFailure wrapping).
        let clientWithEmptyURL = Client(Configuration(vaultID: "id", vaultURL: "", tokenProvider: DemoTokenProvider()))
        let revealContainer = clientWithEmptyURL.container(type: ContainerType.REVEAL, options: nil)

        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Reveal with empty vaultURL should fail"))
        revealContainer?.reveal(callback: callback)

        XCTAssertEqual(callback.receivedResponse, ErrorCodes.EMPTY_VAULT_URL().getErrorObject(contextOptions: ContextOptions(interface: .REVEAL_CONTAINER)).localizedDescription)
    }

    func testDetokenizeEmptyVaultURL() {
        // Client.detokenize()'s vault-level errors route through callRevealOnFailure, which
        // wraps the NSError in {"errors": [errorObject]} rather than passing it through raw.
        let expectation = XCTestExpectation(description: "Detokenize with empty vaultURL should fail")
        let callback = DemoAPICallback(expectation: expectation)
        let clientWithEmptyURL = Client(Configuration(vaultID: "id", vaultURL: "", tokenProvider: DemoTokenProvider()))

        clientWithEmptyURL.detokenize(records: ["records": [["token": "sometoken"]]], callback: callback)

        wait(for: [expectation], timeout: 10.0)
        let errors = callback.data["errors"] as! [NSError]
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0].localizedDescription, ErrorCodes.EMPTY_VAULT_URL().description)
    }

}
