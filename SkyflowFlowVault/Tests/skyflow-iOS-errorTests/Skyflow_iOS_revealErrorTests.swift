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
@testable import SkyflowFlowVault
@testable import SkyflowCore

// swiftlint:disable:next type_body_length
class Skyflow_iOS_revealErrorTests: XCTestCase {
    var skyflow: Client!
    var revealTestId: String!

    override func setUp() {
        self.skyflow = Client(Configuration(
            vaultID: (ProcessInfo.processInfo.environment["VAULT_ID"] ?? "dummy_vault_id"),
            vaultURL: (ProcessInfo.processInfo.environment["VAULT_URL"] ?? "https://dummy.vault.skyflowapis.dev/"),
            tokenProvider: DemoTokenProvider(),
            options: Options(logLevel: .DEBUG)))
        self.revealTestId = "6255-9119-4502-5915"
    }

    override func tearDown() {
        skyflow = nil
    }

    func testContainerRevealWithUnmountedElements() {
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)

        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        let styles = Styles(base: bstyle)

        let revealElementInput = RevealElementInput(token: revealTestId, inputStyles: styles, label: "RevealElement")
        let revealElement = revealContainer?.create(input: revealElementInput, options: RevealElementOptions())

        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Should return reveal output"))
        revealContainer?.reveal(callback: callback.asRevealCallback)

        let result = callback.receivedResponse

        XCTAssertEqual(result, ErrorCodes.UNMOUNTED_REVEAL_ELEMENT(value: revealTestId).describedFor(productName: "SkyflowFlowVault"))
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
        revealContainer?.reveal(callback: callback.asRevealCallback)

        let result = callback.receivedResponse

        XCTAssertEqual(result,  ErrorCodes.EMPTY_TOKEN_ID().describedFor(productName: "SkyflowFlowVault"))
    }

    func testContainerRevealEmptyVaultURL() {
        // Unlike Client.detokenize()/getById()/get(), RevealContainer.reveal() calls
        // callback.onFailure directly with the raw NSError (no callRevealOnFailure wrapping).
        let clientWithEmptyURL = Client(Configuration(vaultID: "id", vaultURL: "", tokenProvider: DemoTokenProvider()))
        let revealContainer = clientWithEmptyURL.container(type: ContainerType.REVEAL, options: nil)

        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Reveal with empty vaultURL should fail"))
        revealContainer?.reveal(callback: callback.asRevealCallback)

        XCTAssertEqual(callback.receivedResponse, ErrorCodes.EMPTY_VAULT_URL().getErrorObject(contextOptions: ContextOptions(interface: .REVEAL_CONTAINER, productName: "SkyflowFlowVault")).localizedDescription)
    }

}
