/*
 * Copyright (c) 2022 Skyflow
*/

// Pins the SDK-name identity for SkyflowFlowVault at all three layers it surfaces:
//   1. ContextOptions.sdkName, set by Client.init - the single source of truth
//   2. the Log tag, which used to be hardcoded to "[Skyflow]" for BOTH SDKs, making their
//      output indistinguishable when an app installs both pods
//   3. sky-metadata's sdk_name_version, sent on every request
//
// A matching file exists on the legacy side (Skyflow/Tests/skyflow-iOS-legacyTests/
// SdkNameIdentityTests.swift). Both are needed: the value is per-SDK, so a single test can only
// ever prove one half, and the interesting failure is the two SDKs reporting the same name.

import XCTest
@testable import SkyflowFlowVault
@testable import SkyflowCore

final class SdkNameIdentityTests: XCTestCase {

    /// The name SkyflowFlowVault identifies itself by. Declared here as a literal on purpose:
    /// if someone changes ClientOperations.swift's sdkName, this test should fail rather than
    /// silently follow along (which is the flaw in the pre-existing FetchMetrices tests - they
    /// pass a name in and assert it comes back out, so they only test concatenation).
    private static let expectedSdkName = "SkyflowFlowVault"

    private func makeClient() -> Client {
        Client(Configuration(vaultID: "id", vaultURL: "https://example.org/",
                             tokenProvider: DemoTokenProvider(), options: Options(logLevel: .DEBUG)))
    }

    /// Runs `body` with stdout redirected, returning whatever was printed. Used because Log
    /// writes via print() - there is no injectable sink to assert against.
    private func captureStdout(_ body: () -> Void) -> String {
        let pipe = Pipe()
        let originalStdout = dup(STDOUT_FILENO)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)

        body()

        fflush(stdout)
        dup2(originalStdout, STDOUT_FILENO)
        close(originalStdout)
        try? pipe.fileHandleForWriting.close()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - Layer 1: the source of truth

    func testClientInitSetsFlowVaultSdkNameOnContextOptions() {
        XCTAssertEqual(makeClient().contextOptions.sdkName, Self.expectedSdkName)
    }

    func testSdkNameIsNotTheLegacyDefault() {
        // ContextOptions defaults sdkName to "skyflow-iOS", so a FlowVault code path that built a
        // bare ContextOptions() would silently label itself as the legacy SDK.
        XCTAssertNotEqual(makeClient().contextOptions.sdkName, "skyflow-iOS")
    }

    func testClientInitSetsFlowVaultProductName() {
        // productName drives the log tag and the error-message prefix. It defaults to "" (the
        // legacy opt-out), so FlowVault has to set it explicitly.
        XCTAssertEqual(makeClient().contextOptions.productName, Self.expectedSdkName)
    }

    // MARK: - Layer 2: the log tag

    func testLogTagUsesFlowVaultSdkName() {
        let contextOptions = makeClient().contextOptions
        let output = captureStdout {
            Log.info(message: .COLLECT_SUBMIT_SUCCESS, contextOptions: contextOptions)
        }

        XCTAssertTrue(output.contains("[\(Self.expectedSdkName)]"),
                      "log line should be tagged with the SDK name, got: \(output)")
        XCTAssertFalse(output.contains("[Skyflow]"),
                       "the tag must not be the old hardcoded \"[Skyflow]\" - that made both SDKs' logs identical")
    }

    func testLogTagFollowsWhateverProductNameIsSetRatherThanBeingHardcoded() {
        // Proves the tag is genuinely derived from contextOptions rather than matching by luck.
        var contextOptions = makeClient().contextOptions
        contextOptions.productName = "a-deliberately-unusual-name"
        let output = captureStdout {
            Log.info(message: .COLLECT_SUBMIT_SUCCESS, contextOptions: contextOptions)
        }
        XCTAssertTrue(output.contains("[a-deliberately-unusual-name]"), "got: \(output)")
    }

    /// The tag comes from productName, not sdkName - sdkName stays a pure telemetry key. Changing
    /// it must leave the log tag alone.
    func testLogTagIgnoresSdkName() {
        var contextOptions = makeClient().contextOptions
        contextOptions.sdkName = "some-telemetry-only-key"
        let output = captureStdout {
            Log.info(message: .COLLECT_SUBMIT_SUCCESS, contextOptions: contextOptions)
        }
        XCTAssertTrue(output.contains("[\(Self.expectedSdkName)]"), "got: \(output)")
        XCTAssertFalse(output.contains("some-telemetry-only-key"), "got: \(output)")
    }

    /// An empty productName is the legacy opt-out and must fall back to the original tag - this is
    /// what keeps legacy log output byte-identical.
    func testEmptyProductNameFallsBackToTheLegacyTag() {
        var contextOptions = makeClient().contextOptions
        contextOptions.productName = ""
        let output = captureStdout {
            Log.info(message: .COLLECT_SUBMIT_SUCCESS, contextOptions: contextOptions)
        }
        XCTAssertTrue(output.contains("[Skyflow]"), "got: \(output)")
    }

    func testErrorLogTagAlsoUsesSdkName() {
        // Log.error takes a String rather than a Message and has its own format string, so it
        // needed the same change and can regress independently of the other three levels.
        let output = captureStdout {
            Log.error(message: "something failed", contextOptions: makeClient().contextOptions)
        }
        XCTAssertTrue(output.contains("[\(Self.expectedSdkName)]"), "got: \(output)")
        XCTAssertFalse(output.contains("[Skyflow]"), "got: \(output)")
    }

    func testAllLogLevelsCarryTheSdkName() {
        let contextOptions = makeClient().contextOptions
        for level in [0, 1, 2] {
            let output = captureStdout {
                switch level {
                case 0: Log.debug(message: .COLLECT_SUBMIT_SUCCESS, contextOptions: contextOptions)
                case 1: Log.info(message: .COLLECT_SUBMIT_SUCCESS, contextOptions: contextOptions)
                default: Log.warn(message: .COLLECT_SUBMIT_SUCCESS, contextOptions: contextOptions)
                }
            }
            XCTAssertTrue(output.contains("[\(Self.expectedSdkName)]"),
                          "log level \(level) lost the SDK name, got: \(output)")
        }
    }

    // MARK: - Layer 3: the sky-metadata header

    func testMetadataHeaderCarriesFlowVaultSdkNameAndVersion() {
        // Derived from the client's own contextOptions, not a hand-passed literal - so this
        // exercises the value the SDK actually puts on the wire.
        let sdkName = makeClient().contextOptions.sdkName
        let header = FetchMetrices().buildMetadataHeaderValue(sdkName: sdkName)

        XCTAssertTrue(header.contains("\(Self.expectedSdkName)@\(SDK_VERSION)"),
                      "sky-metadata should carry \(Self.expectedSdkName)@<version>, got: \(header)")
    }

    func testMetadataSdkNameVersionFieldIsWellFormed() {
        let sdkName = makeClient().contextOptions.sdkName
        let metrics = FetchMetrices().getMetrices(sdkName: sdkName)

        XCTAssertEqual(metrics["sdk_name_version"] as? String, "\(Self.expectedSdkName)@\(SDK_VERSION)")
    }

    // MARK: - Layer 4: validation error text

    func testValidationErrorTextCarriesTheProductPrefix() {
        let contextOptions = makeClient().contextOptions
        let message = ErrorCodes.EMPTY_VAULT_ID().getErrorObject(contextOptions: contextOptions)
            .localizedDescription

        XCTAssertTrue(message.hasPrefix("\(Self.expectedSdkName) iOS SDK v"),
                      "expected \"SkyflowFlowVault iOS SDK v...\", got: \(message)")
    }

    /// The prefix is inserted, not substituted - the original message body must survive intact.
    func testProductPrefixIsPrependedWithoutLosingTheOriginalMessage() {
        let contextOptions = makeClient().contextOptions
        let code = ErrorCodes.EMPTY_VAULT_ID()

        XCTAssertEqual(code.getErrorObject(contextOptions: contextOptions).localizedDescription,
                       "\(Self.expectedSdkName) \(code.description)")
    }

    /// Messages that don't carry the "iOS SDK v<version>" stamp are caller-supplied text and must
    /// never get an SDK name glued onto them.
    func testUnstampedMessagesAreNotPrefixed() {
        let code = ErrorCodes.ERROR_TRIGGERED(value: "my own error")

        XCTAssertEqual(code.describedFor(productName: Self.expectedSdkName), code.description)
    }
}
