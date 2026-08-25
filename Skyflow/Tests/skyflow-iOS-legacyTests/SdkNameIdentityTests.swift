/*
 * Copyright (c) 2022 Skyflow
*/

// Legacy-side counterpart to SkyflowFlowVault/Tests/skyflow-iOS-utilTests/SdkNameIdentityTests.swift.
// Both halves are needed: the identity is per-SDK, so a single test can only ever prove one of
// them, and the failure that matters is the two SDKs reporting the SAME name.
//
// This half's job is the stricter one: the legacy SDK's observable output must stay byte-identical
// to what it was before FlowVault got its own identity. All three channels are pinned below.

import UIKit
import XCTest
@testable import Skyflow
@testable import SkyflowCore

final class SdkNameIdentityTests: XCTestCase {

    /// The telemetry key in sky-metadata's sdk_name_version. A literal on purpose - if someone
    /// changes ClientOperations.swift's sdkName this should fail loudly rather than track the
    /// change, because the value is already on the wire and renaming it breaks vault queries.
    private static let expectedSdkName = "skyflow-iOS"

    /// The log tag. Deliberately NOT expectedSdkName: the tag is display text and has always read
    /// "[Skyflow]". The two differ, which is exactly why productName is a separate field.
    private static let expectedLogTag = "Skyflow"

    private func makeClient() -> Client {
        Client(Configuration(vaultID: "id", vaultURL: "https://example.org/",
                             tokenProvider: DemoTokenProvider(), options: Options(logLevel: .DEBUG)))
    }

    /// Log writes via print(), so stdout redirection is the only way to assert on the tag.
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

    func testClientInitSetsLegacySdkNameOnContextOptions() {
        XCTAssertEqual(makeClient().contextOptions.sdkName, Self.expectedSdkName)
    }

    func testLegacySdkNameIsNotTheFlowVaultName() {
        XCTAssertNotEqual(makeClient().contextOptions.sdkName, "SkyflowFlowVault")
    }

    /// The legacy SDK opts out of the product-name feature entirely. An empty productName is what
    /// suppresses both the log-tag override and the error-message prefix, so if someone ever sets
    /// it here the other tests in this file would start reporting FlowVault-shaped output.
    func testLegacyClientDoesNotSetAProductName() {
        XCTAssertEqual(makeClient().contextOptions.productName, "")
    }

    // MARK: - Layer 2: the log tag

    func testLogTagIsUnchangedLegacyTag() {
        let output = captureStdout {
            Log.info(message: .INSERT_DATA_SUCCESS, contextOptions: makeClient().contextOptions)
        }

        XCTAssertTrue(output.contains("[\(Self.expectedLogTag)]"),
                      "legacy log tag must stay \"[\(Self.expectedLogTag)]\", got: \(output)")
        XCTAssertFalse(output.contains("[SkyflowFlowVault]"), "got: \(output)")
        // Guards against the tag being switched to the telemetry key, which would be a visible
        // change to legacy output.
        XCTAssertFalse(output.contains("[\(Self.expectedSdkName)]"), "got: \(output)")
    }

    func testErrorLogTagAlsoUsesLegacyTag() {
        // Log.error has its own format string and can regress independently of the other levels.
        let output = captureStdout {
            Log.error(message: "something failed", contextOptions: makeClient().contextOptions)
        }
        XCTAssertTrue(output.contains("[\(Self.expectedLogTag)]"), "got: \(output)")
    }

    func testAllLogLevelsCarryTheLegacyTag() {
        let contextOptions = makeClient().contextOptions
        for level in [0, 1, 2] {
            let output = captureStdout {
                switch level {
                case 0: Log.debug(message: .INSERT_DATA_SUCCESS, contextOptions: contextOptions)
                case 1: Log.info(message: .INSERT_DATA_SUCCESS, contextOptions: contextOptions)
                default: Log.warn(message: .INSERT_DATA_SUCCESS, contextOptions: contextOptions)
                }
            }
            XCTAssertTrue(output.contains("[\(Self.expectedLogTag)]"),
                          "log level \(level) lost the legacy tag, got: \(output)")
        }
    }

    // MARK: - Layer 3: the sky-metadata header

    func testMetadataHeaderCarriesLegacySdkNameAndVersion() {
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

    /// The legacy message must carry no product-name prefix at all - it starts at the bare
    /// "iOS SDK v<version>" stamp, exactly as it did before FlowVault got its own prefix.
    func testValidationErrorTextCarriesNoProductPrefix() {
        let contextOptions = makeClient().contextOptions
        let message = ErrorCodes.EMPTY_VAULT_ID().getErrorObject(contextOptions: contextOptions)
            .localizedDescription

        XCTAssertTrue(message.hasPrefix(LangAndVersion),
                      "legacy error text must start at the version stamp, got: \(message)")
        XCTAssertFalse(message.contains("SkyflowFlowVault"), "got: \(message)")
    }

    /// Pins the whole string, not just the prefix, so any future change to legacy error text has
    /// to be deliberate.
    func testValidationErrorTextIsExactlyTheUnprefixedDescription() {
        let contextOptions = makeClient().contextOptions
        let code = ErrorCodes.EMPTY_VAULT_ID()

        XCTAssertEqual(code.getErrorObject(contextOptions: contextOptions).localizedDescription,
                       code.description)
    }
}
