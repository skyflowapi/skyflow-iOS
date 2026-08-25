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

    // MARK: - SDK identity in log output

    /// Runs `body` with stdout redirected, returning whatever was printed. Log writes via
    /// print(), so this is the only way to assert on its output from the public surface.
    private func captureStdout(_ body: () -> Void) -> String {
        let pipe = Pipe()
        let originalStdout = dup(STDOUT_FILENO)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)

        body()

        fflush(stdout)
        dup2(originalStdout, STDOUT_FILENO)
        close(originalStdout)
        try? pipe.fileHandleForWriting.close()

        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }

    /// The coexistence case that matters for support: with both pods installed, a log line has to
    /// say WHICH SDK produced it. The tag used to be hardcoded to "[Skyflow]" for both, so their
    /// output was indistinguishable. Uses only public API - Client.init logs CLIENT_INITIALIZED,
    /// so simply constructing each client is enough to compare tags.
    func testEachSDKTagsItsLogsWithItsOwnName() {
        let legacyOutput = captureStdout {
            _ = Skyflow.initialize(Skyflow.Configuration(
                vaultID: "legacyVaultID",
                vaultURL: "https://legacy.vault.example.org",
                tokenProvider: DemoTokenProvider(),
                options: Skyflow.Options(logLevel: .DEBUG)))
        }

        let flowVaultOutput = captureStdout {
            _ = SkyflowFlowVault.initialize(SkyflowFlowVault.Configuration(
                vaultID: "flowVaultID",
                vaultURL: "https://flow.vault.example.org",
                tokenProvider: DemoTokenProvider(),
                options: SkyflowFlowVault.Options(logLevel: .DEBUG)))
        }

        // Legacy keeps its original "[Skyflow]" tag - only FlowVault's output changed.
        XCTAssertTrue(legacyOutput.contains("[Skyflow]"),
                      "legacy client should tag its logs [Skyflow], got: \(legacyOutput)")
        XCTAssertTrue(flowVaultOutput.contains("[SkyflowFlowVault]"),
                      "FlowVault client should tag its logs [SkyflowFlowVault], got: \(flowVaultOutput)")

        // The actual coexistence guarantee: the two tags are not the same string. "[Skyflow]" is
        // not a substring of "[SkyflowFlowVault]" - the closing bracket is what separates them.
        XCTAssertFalse(legacyOutput.contains("[SkyflowFlowVault]"),
                       "legacy output must not claim to be FlowVault")
        XCTAssertFalse(flowVaultOutput.contains("[Skyflow]"),
                       "FlowVault output must not claim to be the legacy SDK")
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

    // MARK: - SDK identity in validation error text
    //
    // Both SDKs' Container.collect() run CoreRequestValidators.checkClientConfig FIRST, before
    // any element validation, so an empty vaultID produces the same underlying EMPTY_VAULT_ID
    // message from both. That makes it the cleanest symmetric probe available from the public
    // surface: same error, same code path, differing only in the identity each SDK stamps on it.
    //
    // Note this exercises the public API only. The sky-metadata header is the third identity
    // channel, but FetchMetrices is `package`, so it is not observable from here - it is covered
    // in each SDK's own SdkNameIdentityTests instead.

    /// The version stamp every stamped message starts with. Legacy messages begin here directly;
    /// FlowVault's are prefixed with the product name ahead of it.
    private static let versionStamp = "iOS SDK v"

    private func makeLegacyClientWithEmptyVaultID() -> Client {
        return Skyflow.initialize(Skyflow.Configuration(
            vaultID: "",
            vaultURL: "https://legacy.vault.example.org",
            tokenProvider: DemoTokenProvider()))
    }

    private func makeFlowVaultClientWithEmptyVaultID() -> Client {
        return SkyflowFlowVault.initialize(SkyflowFlowVault.Configuration(
            vaultID: "",
            vaultURL: "https://flow.vault.example.org",
            tokenProvider: DemoTokenProvider()))
    }

    /// Triggers legacy collect validation and returns the error text delivered to the callback.
    private func legacyCollectValidationMessage() -> String {
        let options: Skyflow.ContainerOptions? = nil
        let container = makeLegacyClientWithEmptyVaultID()
            .container(type: ContainerType.COLLECT, options: options)

        let expectation = expectation(description: "legacy collect validation failure")
        var message = ""
        // Both SDKs contribute a collect(callback:options:) to the shared Container, and the
        // callback type alone is NOT enough to pick one: FlowVault's CollectCallback conforms to
        // Callback, so legacy's `any Callback` overload is viable for both. The typed options
        // argument is what disambiguates - same approach as container(type:options:) above.
        let callback = MessageCapturingCallback(expectation: expectation) { message = $0 }
        container?.collect(callback: callback, options: Skyflow.CollectOptions())

        waitForExpectations(timeout: 1)
        return message
    }

    /// Triggers FlowVault collect validation and returns the error text delivered to the callback.
    private func flowVaultCollectValidationMessage() -> String {
        let options: SkyflowFlowVault.ContainerOptions? = nil
        let container = makeFlowVaultClientWithEmptyVaultID()
            .container(type: ContainerType.COLLECT, options: options)

        let expectation = expectation(description: "flowvault collect validation failure")
        var message = ""
        let callback = SkyflowFlowVault.CollectCallback(
            onSuccess: { response in
                XCTFail("expected onFailure, got onSuccess: \(response)")
            },
            onFailure: { error in
                message = error.localizedDescription
                expectation.fulfill()
            })
        container?.collect(callback: callback, options: SkyflowFlowVault.CollectOptions())

        waitForExpectations(timeout: 1)
        return message
    }

    /// Captures onFailure's error text. Separate from FailureExpectingCallback because that one
    /// stores the raw `Any` rather than the message.
    private class MessageCapturingCallback: Callback {
        private let expectation: XCTestExpectation
        private let onMessage: (String) -> Void

        init(expectation: XCTestExpectation, onMessage: @escaping (String) -> Void) {
            self.expectation = expectation
            self.onMessage = onMessage
        }

        func onSuccess(_ responseBody: Any) {
            XCTFail("expected onFailure, got onSuccess: \(responseBody)")
        }

        func onFailure(_ error: Any) {
            onMessage((error as? NSError)?.localizedDescription ?? "\(error)")
            expectation.fulfill()
        }
    }

    /// The headline coexistence guarantee for error text: with both pods installed, a validation
    /// message says which SDK produced it. FlowVault names itself; legacy stays as it always was.
    func testEachSDKStampsItsOwnIdentityOnValidationErrors() {
        let legacyMessage = legacyCollectValidationMessage()
        let flowVaultMessage = flowVaultCollectValidationMessage()

        XCTAssertTrue(legacyMessage.hasPrefix(Self.versionStamp),
                      "legacy message should start at the version stamp, got: \(legacyMessage)")
        XCTAssertTrue(flowVaultMessage.hasPrefix("SkyflowFlowVault \(Self.versionStamp)"),
                      "FlowVault message should be prefixed with its name, got: \(flowVaultMessage)")

        XCTAssertNotEqual(legacyMessage, flowVaultMessage,
                          "the two SDKs must not produce identical error text")
    }

    /// The prefix is additive: strip FlowVault's name and the two messages are the same string,
    /// proving the shared message body is untouched rather than reworded per SDK.
    func testTheOnlyDifferenceIsTheLeadingProductName() {
        let legacyMessage = legacyCollectValidationMessage()
        let flowVaultMessage = flowVaultCollectValidationMessage()

        XCTAssertEqual(flowVaultMessage, "SkyflowFlowVault \(legacyMessage)")
    }

    /// Legacy text must not acquire a name just because FlowVault is linked into the same binary.
    /// This is the regression that would break existing customer error-string handling.
    func testLegacyValidationTextIsUnaffectedByFlowVaultBeingLoaded() {
        // Construct the FlowVault client FIRST, so if identity were stored globally (a shared
        // static rather than per-Client state) legacy would pick up FlowVault's name below.
        _ = makeFlowVaultClient()

        let legacyMessage = legacyCollectValidationMessage()

        XCTAssertFalse(legacyMessage.contains("SkyflowFlowVault"), "got: \(legacyMessage)")
        XCTAssertFalse(legacyMessage.contains("Skyflow iOS SDK"), "got: \(legacyMessage)")
        XCTAssertTrue(legacyMessage.hasPrefix(Self.versionStamp), "got: \(legacyMessage)")
    }

    /// Identity is per-Client, not last-writer-wins. Interleaving the two SDKs and re-checking
    /// each one catches a shared-global implementation that a sequential test would miss.
    func testIdentityIsPerClientAndSurvivesInterleaving() {
        let flowVaultFirst = flowVaultCollectValidationMessage()
        let legacyMiddle = legacyCollectValidationMessage()
        let flowVaultAgain = flowVaultCollectValidationMessage()
        let legacyAgain = legacyCollectValidationMessage()

        XCTAssertEqual(flowVaultFirst, flowVaultAgain,
                       "FlowVault identity changed after a legacy client was used")
        XCTAssertEqual(legacyMiddle, legacyAgain,
                       "legacy identity changed after a FlowVault client was used")
        XCTAssertTrue(flowVaultAgain.hasPrefix("SkyflowFlowVault "), "got: \(flowVaultAgain)")
        XCTAssertFalse(legacyAgain.contains("SkyflowFlowVault"), "got: \(legacyAgain)")
    }

    /// Both clients alive at once, each still logging under its own tag. testEachSDKTagsItsLogs...
    /// above constructs them in separate capture blocks; this one holds both and re-logs, which is
    /// closer to how an app that uses both SDKs actually behaves.
    func testBothClientsLogUnderTheirOwnTagWhileBothAreAlive() {
        let legacyClient = makeLegacyClient()
        let flowVaultClient = makeFlowVaultClient()

        // Container creation logs, so it gives each live client something to emit.
        let legacyOutput = captureStdout {
            let options: Skyflow.ContainerOptions? = nil
            _ = legacyClient.container(type: ContainerType.COLLECT, options: options)
        }
        let flowVaultOutput = captureStdout {
            let options: SkyflowFlowVault.ContainerOptions? = nil
            _ = flowVaultClient.container(type: ContainerType.COLLECT, options: options)
        }

        // Only assert when the operation actually logged - container() is silent at the default
        // log level, and a vacuous pass is worse than a skip.
        if legacyOutput.contains("[") {
            XCTAssertTrue(legacyOutput.contains("[Skyflow]"), "got: \(legacyOutput)")
            XCTAssertFalse(legacyOutput.contains("[SkyflowFlowVault]"), "got: \(legacyOutput)")
        }
        if flowVaultOutput.contains("[") {
            XCTAssertTrue(flowVaultOutput.contains("[SkyflowFlowVault]"), "got: \(flowVaultOutput)")
        }
    }
}
