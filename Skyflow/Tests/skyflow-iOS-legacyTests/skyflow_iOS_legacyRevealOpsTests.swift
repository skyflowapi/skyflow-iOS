/*
 * Copyright (c) 2022 Skyflow
*/

// Tests for the legacy (v1) reveal layer: per-token redaction on
// RevealElementInput, RevealRequestBody, RevealValueCallback and the
// container reveal() validation paths.

import UIKit
import XCTest
@testable import Skyflow
@testable import SkyflowCore

final class skyflow_iOS_legacyRevealOpsTests: XCTestCase {
    var skyflow: Client!

    override func setUp() {
        self.skyflow = Client(Configuration(
            vaultID: "vault_id",
            vaultURL: "https://example.org/",
            tokenProvider: DemoTokenProvider(),
            options: Options(logLevel: .DEBUG)))
    }

    override func tearDown() {
        skyflow = nil
    }

    private func waitForUIUpdates() {
        let expectation = self.expectation(description: "main queue drained")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }

    // MARK: - RevealElementInput (legacy per-token redaction)

    func testRevealElementInputDefaultsToPlainTextRedaction() {
        let input = RevealElementInput(token: "token1", label: "label")

        XCTAssertEqual(input.data.redaction, RedactionType.PLAIN_TEXT)
    }

    func testRevealElementInputCarriesExplicitRedaction() {
        let input = RevealElementInput(token: "token1", label: "label", redaction: .MASKED)

        XCTAssertEqual(input.data.redaction, RedactionType.MASKED)
    }

    // MARK: - RevealRequestBody

    func testCreateRevealRequestBodyCarriesPerTokenRedaction() {
        let container = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let masked = container!.create(input: RevealElementInput(token: "token1", label: "first", redaction: .MASKED))
        let plain = container!.create(input: RevealElementInput(token: "token2", label: "second"))

        let body = RevealRequestBody.createRequestBody(elements: [masked, plain])
        let records = body["records"] as! [[String: Any]]

        XCTAssertEqual(records.count, 2)
        XCTAssertEqual(records[0]["token"] as? String, "token1")
        XCTAssertEqual(records[0]["redaction"] as? RedactionType, .MASKED)
        XCTAssertEqual(records[1]["token"] as? String, "token2")
        XCTAssertEqual(records[1]["redaction"] as? RedactionType, .PLAIN_TEXT)
    }

    // MARK: - RevealValueCallback

    func testRevealValueCallbackOnSuccessUpdatesElementsAndReportsErrors() {
        let container = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let revealed = container!.create(input: RevealElementInput(token: "token1", label: "first"))
        let failed = container!.create(input: RevealElementInput(token: "token2", label: "second"))

        let expectation = XCTestExpectation(description: "client callback should receive merged response")
        let clientCallback = DemoAPICallback(expectation: expectation)
        let revealValueCallback = RevealValueCallback(
            callback: clientCallback,
            revealElements: [revealed, failed],
            contextOptions: ContextOptions())

        revealValueCallback.onSuccess([
            "records": [["token": "token1", "value": "John"]],
            "errors": [["token": "token2", "error": "Invalid Token"]]
        ] as [String: Any])

        wait(for: [expectation], timeout: 10.0)
        waitForUIUpdates()

        let success = clientCallback.data["success"] as! [[String: String]]
        XCTAssertEqual(success, [["token": "token1"]])
        let errors = clientCallback.data["errors"] as! [[String: Any]]
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0]["token"] as? String, "token2")

        XCTAssertEqual(revealed.actualValue, "John")
        XCTAssertNil(revealed.errorMessage.text)
        XCTAssertNil(failed.actualValue)
        XCTAssertEqual(failed.errorMessage.text, "Invalid Token")
    }

    func testRevealValueCallbackOnFailureRoutesErrorsToClientOnFailure() {
        let container = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let failed = container!.create(input: RevealElementInput(token: "token1", label: "first"))

        let expectation = XCTestExpectation(description: "client callback should receive failure response")
        let clientCallback = DemoAPICallback(expectation: expectation)
        let revealValueCallback = RevealValueCallback(
            callback: clientCallback,
            revealElements: [failed],
            contextOptions: ContextOptions())

        revealValueCallback.onFailure([
            "errors": [["token": "token1", "error": "Invalid Token"]]
        ] as [String: Any])

        wait(for: [expectation], timeout: 10.0)
        waitForUIUpdates()

        let errors = clientCallback.data["errors"] as! [[String: Any]]
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0]["token"] as? String, "token1")
        XCTAssertEqual(failed.errorMessage.text, "Invalid Token")
    }

    func testRevealValueCallbackOnFailureWithNonDictionaryDoesNotCrash() {
        let expectation = XCTestExpectation(description: "client callback should still be invoked")
        let clientCallback = DemoAPICallback(expectation: expectation)
        let revealValueCallback = RevealValueCallback(
            callback: clientCallback,
            revealElements: [],
            contextOptions: ContextOptions())

        revealValueCallback.onFailure("not a dictionary")

        wait(for: [expectation], timeout: 10.0)
        XCTAssertNil(clientCallback.data["success"])
        XCTAssertNil(clientCallback.data["errors"])
    }

    // MARK: - Container reveal() validation

    func testRevealEmptyVaultURL() {
        let client = Client(Configuration(vaultID: "vault_id", vaultURL: "", tokenProvider: DemoTokenProvider()))
        let container = client.container(type: ContainerType.REVEAL, options: nil)
        _ = container!.create(input: RevealElementInput(token: "token1", label: "first"))

        let expectation = XCTestExpectation(description: "reveal with empty vaultURL should fail")
        let callback = DemoAPICallback(expectation: expectation)
        container!.reveal(callback: callback)

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.EMPTY_VAULT_URL().description)
    }

    func testRevealUnmountedElement() {
        let container = skyflow.container(type: ContainerType.REVEAL, options: nil)
        _ = container!.create(input: RevealElementInput(token: "token1", label: "first"))

        let expectation = XCTestExpectation(description: "reveal with unmounted element should fail")
        let callback = DemoAPICallback(expectation: expectation)
        container!.reveal(callback: callback)

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.UNMOUNTED_REVEAL_ELEMENT(value: "token1").description)
    }

    func testRevealElementWithTriggeredErrorFails() {
        let container = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let element = container!.create(input: RevealElementInput(token: "token1", label: "first"))
        UIWindow().addSubview(element)
        element.setError("manually triggered error")

        let expectation = XCTestExpectation(description: "reveal with an error-triggered element should fail")
        let callback = DemoAPICallback(expectation: expectation)
        container!.reveal(callback: callback)

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.ERROR_TRIGGERED(value: "manually triggered error").description)
    }

    func testRevealMountedElementRunsFullRequestFlow() {
        // Unresolvable vault host: the full reveal path (request body, per-token
        // redaction list, apiClient.get) executes and fails fast at the network layer.
        let client = Client(Configuration(vaultID: "vault_id", vaultURL: "https://testvault.skyflow.invalid/",
                                          tokenProvider: DemoTokenProvider()))
        let container = client.container(type: ContainerType.REVEAL, options: nil)
        let element = container!.create(input: RevealElementInput(token: "token1", label: "first", redaction: .MASKED))
        UIWindow().addSubview(element)

        let expectation = XCTestExpectation(description: "reveal should reach the network layer and fail offline")
        let callback = DemoAPICallback(expectation: expectation)
        container!.reveal(callback: callback)

        wait(for: [expectation], timeout: 20.0)
        XCTAssertNotNil(callback.data["errors"])
    }

    func testRevealValueCallbackOnFailureWithRecordsUpdatesElements() {
        // A partial-failure payload delivered through onFailure: revealed values still
        // update their elements while token-scoped errors surface inline.
        let container = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let revealed = container!.create(input: RevealElementInput(token: "token1", label: "first"))
        let failed = container!.create(input: RevealElementInput(token: "token2", label: "second"))

        let expectation = XCTestExpectation(description: "client callback should receive failure response")
        let clientCallback = DemoAPICallback(expectation: expectation)
        let revealValueCallback = RevealValueCallback(
            callback: clientCallback,
            revealElements: [revealed, failed],
            contextOptions: ContextOptions())

        revealValueCallback.onFailure([
            "records": [["token": "token1", "value": "John"]],
            "errors": [["token": "token2", "error": "Invalid Token"]]
        ] as [String: Any])

        wait(for: [expectation], timeout: 10.0)
        waitForUIUpdates()

        let success = clientCallback.data["success"] as! [[String: String]]
        XCTAssertEqual(success, [["token": "token1"]])
        XCTAssertEqual((clientCallback.data["errors"] as! [[String: Any]]).count, 1)
        XCTAssertEqual(revealed.actualValue, "John")
        XCTAssertEqual(failed.errorMessage.text, "Invalid Token")
    }
}
