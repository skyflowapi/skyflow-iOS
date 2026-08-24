/*
 * Copyright (c) 2022 Skyflow
*/

// Guards the wire-key contract of the intermediate [String: Any] that
// FlowVaultCollectAPICallback.getCollectResponseBody produces and that CVVTokenReplacer /
// CollectResponse consume.
//
// Background: this intermediate dict was originally cloned from the legacy PDB v1 SDK, which
// renamed the response's token map to "fields" (v1's own wire name). FlowDB v2 calls it
// "tokens", and the public Swift property is CollectRecord.tokens - so the rename produced a
// pointless tokens -> fields -> tokens round trip that (a) hid the v2 contract and (b) masked
// the tokens/hashedData asymmetry behind the "tokens is [:] instead of nil" bug.
//
// These tests fail if anyone reintroduces a rename, drops the conditional, or breaks the
// pass-through fidelity of the token payload.

import XCTest
@testable import SkyflowFlowVault
@testable import SkyflowCore

final class CollectResponseWireKeyContractTests: XCTestCase {
    private var collectCallback: FlowVaultCollectAPICallback!

    override func setUp() {
        super.setUp()
        self.collectCallback = FlowVaultCollectAPICallback(
            callback: DemoAPICallback(expectation: XCTestExpectation()),
            apiClient: APIClient(vaultID: "", vaultURL: "", tokenProvider: DemoTokenProvider()),
            records: ["records": [["table": "table", "fields": ["field": "value"]]]],
            upsert: nil,
            contextOptions: ContextOptions()
        )
    }

    /// Runs a raw v2 response body through getCollectResponseBody and returns the first record.
    private func firstRecord(from responseBody: [String: Any]) throws -> [String: Any] {
        let data = try JSONSerialization.data(withJSONObject: responseBody, options: .fragmentsAllowed)
        let result = try self.collectCallback.getCollectResponseBody(data: data)
        let records = try XCTUnwrap(result["records"] as? [[String: Any]])
        return try XCTUnwrap(records.first)
    }

    // MARK: - Key naming: the intermediate dict must speak v2, not v1

    func testTokenMapKeepsV2WireKeyAndDoesNotUseLegacyFieldsKey() throws {
        let record = try firstRecord(from: ["records": [[
            "skyflowID": "SID",
            "tableName": "cards",
            "tokens": ["card_number": [["token": "tok-1", "tokenGroupName": "deterministic"]]]
        ]]])

        XCTAssertNotNil(record["tokens"], "the token map must be exposed under the v2 wire key \"tokens\"")
        XCTAssertNil(record["fields"], "\"fields\" is the legacy PDB v1 key and must not appear in a v2 response")
    }

    func testHashedDataKeepsItsWireKey() throws {
        let record = try firstRecord(from: ["records": [[
            "skyflowID": "SID",
            "tableName": "cards",
            "hashedData": ["card_number": [["data": "hash-1", "hashName": "hash1"]]]
        ]]])

        XCTAssertNotNil(record["hashedData"])
    }

    // MARK: - tokens / hashedData symmetry (the shape that hid the nil-vs-[:] bug)

    func testBothKeysAbsentWhenNeitherIsInTheResponse() throws {
        let record = try firstRecord(from: ["records": [[
            "skyflowID": "SID", "tableName": "cards", "httpCode": 200
        ]]])

        // Absent, NOT present-with-empty-dict - otherwise `record.tokens == nil` checks in app
        // code silently take the wrong branch.
        XCTAssertNil(record["tokens"])
        XCTAssertNil(record["hashedData"])
    }

    func testTokensAbsentButHashedDataPresentAreHandledIndependently() throws {
        let record = try firstRecord(from: ["records": [[
            "skyflowID": "SID",
            "tableName": "cards",
            "hashedData": ["card_number": [["data": "hash-1", "hashName": "hash1"]]]
        ]]])

        XCTAssertNil(record["tokens"], "a hashedData-only record must not gain an empty tokens map")
        XCTAssertNotNil(record["hashedData"])
    }

    func testHashedDataAbsentButTokensPresentAreHandledIndependently() throws {
        let record = try firstRecord(from: ["records": [[
            "skyflowID": "SID",
            "tableName": "cards",
            "tokens": ["card_number": [["token": "tok-1"]]]
        ]]])

        XCTAssertNotNil(record["tokens"])
        XCTAssertNil(record["hashedData"], "a tokens-only record must not gain an empty hashedData map")
    }

    // MARK: - Pass-through fidelity (buildFieldsDict used to sit here as a no-op deep copy)

    func testTokenPayloadPassesThroughVerbatimIncludingAllTokenAttributes() throws {
        let record = try firstRecord(from: ["records": [[
            "skyflowID": "SID",
            "tableName": "cards",
            "tokens": ["card_number": [[
                "token": "tok-1", "tokenGroupName": "deterministic", "path": "card_number"
            ]]]
        ]]])

        let tokens = try XCTUnwrap(record["tokens"] as? [String: Any])
        let entries = try XCTUnwrap(tokens["card_number"] as? [[String: Any]])
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0]["token"] as? String, "tok-1")
        XCTAssertEqual(entries[0]["tokenGroupName"] as? String, "deterministic")
        XCTAssertEqual(entries[0]["path"] as? String, "card_number")
    }

    func testMultipleColumnsAndMultipleTokenGroupsSurviveIntact() throws {
        let record = try firstRecord(from: ["records": [[
            "skyflowID": "SID",
            "tableName": "cards",
            "tokens": [
                "card_number": [
                    ["token": "tok-det", "tokenGroupName": "deterministic"],
                    ["token": "tok-vault", "tokenGroupName": "vault"]
                ],
                "cvv": [["token": "tok-cvv"]]
            ]
        ]]])

        let tokens = try XCTUnwrap(record["tokens"] as? [String: Any])
        XCTAssertEqual((tokens["card_number"] as? [[String: Any]])?.count, 2)
        XCTAssertEqual((tokens["cvv"] as? [[String: Any]])?.count, 1)
    }

    func testNestedPathColumnKeysSurviveIntact() throws {
        // Dotted/nested column names are how nested vault schemas surface; the old
        // buildFieldsDict recursed over these, so prove removing it changed nothing.
        let record = try firstRecord(from: ["records": [[
            "skyflowID": "SID",
            "tableName": "cards",
            "tokens": ["card.cvv": [["token": "tok-nested"]]]
        ]]])

        let tokens = try XCTUnwrap(record["tokens"] as? [String: Any])
        let entries = try XCTUnwrap(tokens["card.cvv"] as? [[String: Any]])
        XCTAssertEqual(entries[0]["token"] as? String, "tok-nested")
    }

    // MARK: - Error records are untouched by either key

    func testErrorRecordCarriesNeitherTokensNorHashedData() throws {
        let record = try firstRecord(from: ["records": [[
            "error": "Invalid request. Table name is invalid.",
            "httpCode": 400,
            "tableName": ""
        ]]])

        XCTAssertEqual(record["error"] as? String, "Invalid request. Table name is invalid.")
        XCTAssertNil(record["tokens"])
        XCTAssertNil(record["hashedData"])
    }

    // MARK: - End-to-end: intermediate dict -> typed public contract

    func testIntermediateDictFeedsCollectRecordTokensEndToEnd() throws {
        // The whole point of the key contract: whatever getCollectResponseBody emits must be
        // readable by CollectResponse. A mismatch here is invisible at compile time and
        // silently yields record.tokens == nil, which is what the v1-inherited rename risked.
        let data = try JSONSerialization.data(withJSONObject: ["records": [[
            "skyflowID": "SID",
            "tableName": "cards",
            "httpCode": 200,
            "tokens": ["card_number": [["token": "tok-1", "tokenGroupName": "deterministic"]]]
        ]]], options: .fragmentsAllowed)

        let intermediate = try self.collectCallback.getCollectResponseBody(data: data)
        let response = try XCTUnwrap(CollectResponse(intermediate))
        let record = try XCTUnwrap(response.records.first)

        XCTAssertEqual(record.tableName, "cards")
        XCTAssertEqual(record.skyflowId, "SID")
        XCTAssertEqual(record.httpCode, 200)
        XCTAssertEqual(record.tokens?["card_number"]?.first?.token, "tok-1")
        XCTAssertEqual(record.tokens?["card_number"]?.first?.tokenGroupName, "deterministic")
        XCTAssertNil(record.hashedData)
    }

    func testEndToEndTokensNilWhenResponseHasNoTokens() throws {
        let data = try JSONSerialization.data(withJSONObject: ["records": [[
            "skyflowID": "SID", "tableName": "cards", "httpCode": 200
        ]]], options: .fragmentsAllowed)

        let intermediate = try self.collectCallback.getCollectResponseBody(data: data)
        let record = try XCTUnwrap(CollectResponse(intermediate)?.records.first)

        XCTAssertNil(record.tokens, "record.tokens must be nil - not an empty dict - when the vault returned no tokens")
    }

    // MARK: - CVV masking reads the same key (it mutates the intermediate dict in place)

    func testCVVMaskingOperatesOnTheSameWireKey() throws {
        // CVVTokenReplacer sits between getCollectResponseBody and CollectResponse and rewrites
        // the token map in the intermediate dict. If its key and the callback's key ever drift
        // apart, masking silently becomes a no-op and the REAL cvv token reaches the app.
        let data = try JSONSerialization.data(withJSONObject: ["records": [[
            "skyflowID": "SID",
            "tableName": "cards",
            "httpCode": 200,
            "tokens": ["cvv": [["token": "real-cvv-token", "tokenGroupName": "deterministic"]]]
        ]]], options: .fragmentsAllowed)

        let intermediate = try self.collectCallback.getCollectResponseBody(data: data)
        let records = try XCTUnwrap(intermediate["records"] as? [[String: Any]])

        let cvvMap = CVVCaptureMap(byTable: ["cards": ["cvv": "123"]], byRecordId: [:])
        let masked = CVVTokenReplacer.replaceCVVTokens(in: records, cvvMap: cvvMap)

        let tokens = try XCTUnwrap(masked[0]["tokens"] as? [String: Any])
        let cvvEntries = try XCTUnwrap(tokens["cvv"] as? [[String: Any]])
        XCTAssertEqual(cvvEntries[0]["token"] as? String, "817",
                       "3-digit CVV should be replaced with the mock; if this is the real token, the masking key drifted")
    }
}
