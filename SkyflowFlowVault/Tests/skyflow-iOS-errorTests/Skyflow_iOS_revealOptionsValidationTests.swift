/*
 * Copyright (c) 2022 Skyflow
*/

// Unit tests for the tokenGroupRedactions validation in RevealContainer.reveal
// (port of the JS SDK's validateRevealOptions): every entry must have a non-empty,
// non-whitespace tokenGroupName and redaction; failures report the entry index.

import Foundation
import XCTest
@testable import SkyflowFlowVault
@testable import SkyflowCore

class Skyflow_iOS_revealOptionsValidationTests: XCTestCase {
    var skyflow: Client!
    var window: UIWindow!

    override func setUp() {
        self.skyflow = Client(Configuration(vaultID: "id", vaultURL: "http://demo.com", tokenProvider: DemoTokenProvider(), options: Options(logLevel: .DEBUG)))
        self.window = UIWindow()
    }

    override func tearDown() {
        skyflow = nil
        window = nil
    }

    // Builds a container with one mounted, token-bearing element so the reveal call
    // gets past the unmounted/empty-token checks and reaches the options validation.
    private func makeContainerWithMountedElement() -> Container<RevealContainer>? {
        let container = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let input = RevealElementInput(token: "some-token", inputStyles: Styles(), label: "RevealElement")
        let element = container?.create(input: input, options: RevealElementOptions())
        window.addSubview(element!)
        return container
    }

    private func revealAndCaptureError(options: RevealOptions) -> String {
        let container = makeContainerWithMountedElement()
        let callback = DemoAPICallback(expectation: XCTestExpectation(description: "Should fail validation"))
        container?.reveal(callback: callback.asRevealCallback, options: options)
        return callback.receivedResponse
    }

    func testEmptyTokenGroupNameRejected() {
        let result = revealAndCaptureError(options: RevealOptions(tokenGroupRedactions: [
            TokenGroupRedaction(tokenGroupName: "", redaction: "plain_text")
        ]))
        XCTAssertEqual(result, ErrorCodes.INVALID_TOKEN_GROUP_REDACTION_ENTRY(value: "0").describedFor(productName: "SkyflowFlowVault"))
    }

    func testEmptyRedactionRejected() {
        let result = revealAndCaptureError(options: RevealOptions(tokenGroupRedactions: [
            TokenGroupRedaction(tokenGroupName: "deterministic", redaction: "")
        ]))
        XCTAssertEqual(result, ErrorCodes.INVALID_TOKEN_GROUP_REDACTION_ENTRY(value: "0").describedFor(productName: "SkyflowFlowVault"))
    }

    func testWhitespaceOnlyTokenGroupNameRejected() {
        let result = revealAndCaptureError(options: RevealOptions(tokenGroupRedactions: [
            TokenGroupRedaction(tokenGroupName: "   ", redaction: "plain_text")
        ]))
        XCTAssertEqual(result, ErrorCodes.INVALID_TOKEN_GROUP_REDACTION_ENTRY(value: "0").describedFor(productName: "SkyflowFlowVault"))
    }

    func testWhitespaceOnlyRedactionRejected() {
        let result = revealAndCaptureError(options: RevealOptions(tokenGroupRedactions: [
            TokenGroupRedaction(tokenGroupName: "deterministic", redaction: "\n\t ")
        ]))
        XCTAssertEqual(result, ErrorCodes.INVALID_TOKEN_GROUP_REDACTION_ENTRY(value: "0").describedFor(productName: "SkyflowFlowVault"))
    }

    func testInvalidEntryReportsItsIndex() {
        // First entry valid, second invalid: index 1 in the error proves the valid
        // entry passed and the offending one is identified precisely.
        let result = revealAndCaptureError(options: RevealOptions(tokenGroupRedactions: [
            TokenGroupRedaction(tokenGroupName: "deterministic", redaction: "plain_text"),
            TokenGroupRedaction(tokenGroupName: "nondeterministic", redaction: " ")
        ]))
        XCTAssertEqual(result, ErrorCodes.INVALID_TOKEN_GROUP_REDACTION_ENTRY(value: "1").describedFor(productName: "SkyflowFlowVault"))
    }
}
