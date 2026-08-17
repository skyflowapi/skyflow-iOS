/*
 * Copyright (c) 2025 Skyflow
*/

// Coexistence tests: both SDKs imported side by side, the way an app that
// installs both products would. No @testable — only the public API surface.
//
// What coexistence means here:
// - Shared core types (Client, Container, ContainerType, TextField, Label,
//   Callback, TokenProvider, ...) are re-exported by BOTH SDKs but are the
//   SAME declarations, so unqualified use stays unambiguous.
// - Per-SDK wrapper types (Configuration, CollectElementInput, options, ...)
//   are DISTINCT declarations with the same names, so they are used with
//   module qualification: Skyflow.Configuration vs SkyflowFlowVault.Configuration.
// - Same-named member overloads contributed by both SDKs to the shared Client
//   (e.g. container(type:options:)) are disambiguated by their per-SDK
//   parameter types.

import XCTest
import Skyflow
import SkyflowFlowVault

final class skyflow_iOS_coexistenceTests: XCTestCase {
    // TokenProvider and Callback are shared core protocols — one conformance
    // serves both SDKs.
    class DemoTokenProvider: TokenProvider {
        func getBearerToken(_ apiCallback: Callback) {
            apiCallback.onSuccess("demo-token")
        }
    }

    class FailureExpectingCallback: Callback {
        let expectation: XCTestExpectation
        var receivedError: Any?

        init(expectation: XCTestExpectation) {
            self.expectation = expectation
        }

        func onSuccess(_ responseBody: Any) {
            XCTFail("expected onFailure, got onSuccess: \(responseBody)")
        }

        func onFailure(_ error: Any) {
            receivedError = error
            expectation.fulfill()
        }
    }

    private func makeLegacyClient() -> Client {
        return Skyflow.initialize(Skyflow.Configuration(
            vaultID: "legacyVaultID",
            vaultURL: "https://legacy.vault.example.org",
            tokenProvider: DemoTokenProvider()))
    }

    private func makeFlowVaultClient() -> Client {
        return SkyflowFlowVault.initialize(SkyflowFlowVault.Configuration(
            vaultID: "flowVaultID",
            vaultURL: "https://flow.vault.example.org",
            tokenProvider: DemoTokenProvider()))
    }

    // MARK: - Initialization

    func testBothClientsInitializeSideBySide() {
        let legacyClient = makeLegacyClient()
        let flowVaultClient = makeFlowVaultClient()

        XCTAssertNotNil(legacyClient)
        XCTAssertNotNil(flowVaultClient)
        // Both SDKs hand out the one shared core Client class.
        XCTAssertTrue(type(of: legacyClient) == type(of: flowVaultClient))
    }

    // MARK: - Per-SDK wrapper types stay distinct

    func testPerSDKWrapperTypesAreDistinctDeclarations() {
        XCTAssertNotEqual(String(reflecting: Skyflow.Configuration.self),
                          String(reflecting: SkyflowFlowVault.Configuration.self))
        XCTAssertNotEqual(String(reflecting: Skyflow.CollectElementInput.self),
                          String(reflecting: SkyflowFlowVault.CollectElementInput.self))
        XCTAssertNotEqual(String(reflecting: Skyflow.CollectOptions.self),
                          String(reflecting: SkyflowFlowVault.CollectOptions.self))
        XCTAssertNotEqual(String(reflecting: Skyflow.RevealOptions.self),
                          String(reflecting: SkyflowFlowVault.RevealOptions.self))
    }

    // MARK: - Containers and elements from each SDK

    func testCollectContainersAndElementsFromEachSDK() {
        let legacyClient = makeLegacyClient()
        let flowVaultClient = makeFlowVaultClient()

        // Both SDKs extend the shared Client with container(type:options:).
        // A typed options value selects the overload; ContainerType and the
        // returned Container<CollectContainer> are shared core types.
        let legacyOptions: Skyflow.ContainerOptions? = nil
        let legacyCollect = legacyClient.container(type: ContainerType.COLLECT, options: legacyOptions)
        XCTAssertNotNil(legacyCollect)

        let flowVaultOptions: SkyflowFlowVault.ContainerOptions? = nil
        let flowVaultCollect = flowVaultClient.container(type: ContainerType.COLLECT, options: flowVaultOptions)
        XCTAssertNotNil(flowVaultCollect)

        // Element creation uses each SDK's own input wrapper; the produced
        // TextField is the shared core element type.
        let legacyElement = legacyCollect?.create(input: Skyflow.CollectElementInput(
            table: "cards", column: "card_number", type: .CARD_NUMBER))
        XCTAssertNotNil(legacyElement)

        let flowVaultElement = flowVaultCollect?.create(input: SkyflowFlowVault.CollectElementInput(
            tableName: "cards", column: "card_number", type: .CARD_NUMBER))
        XCTAssertNotNil(flowVaultElement)

        XCTAssertTrue(type(of: legacyElement!) == type(of: flowVaultElement!))
    }

    func testRevealContainersFromEachSDK() {
        let legacyClient = makeLegacyClient()
        let flowVaultClient = makeFlowVaultClient()

        let legacyOptions: Skyflow.ContainerOptions? = nil
        let legacyReveal = legacyClient.container(type: ContainerType.REVEAL, options: legacyOptions)
        XCTAssertNotNil(legacyReveal)

        let flowVaultOptions: SkyflowFlowVault.ContainerOptions? = nil
        let flowVaultReveal = flowVaultClient.container(type: ContainerType.REVEAL, options: flowVaultOptions)
        XCTAssertNotNil(flowVaultReveal)

        let legacyLabel = legacyReveal?.create(input: Skyflow.RevealElementInput(
            token: "some-token", label: "card number"))
        XCTAssertNotNil(legacyLabel)

        let flowVaultLabel = flowVaultReveal?.create(input: SkyflowFlowVault.RevealElementInput(
            token: "some-token", label: "card number"))
        XCTAssertNotNil(flowVaultLabel)
    }

    // MARK: - Legacy-only client operations remain callable and validated

    func testLegacyOnlyOperationsStayAvailableWithBothImports() {
        let legacyClient = makeLegacyClient()

        // getById exists only on the legacy SDK's Client extension, so the
        // call is unambiguous even with both modules imported. Missing
        // "records" key fails validation synchronously via the callback.
        let expectation = expectation(description: "getById validation failure")
        let callback = FailureExpectingCallback(expectation: expectation)
        legacyClient.getById(records: [:], callback: callback)

        waitForExpectations(timeout: 1)
        XCTAssertNotNil(callback.receivedError)
    }
}
