/*
 * Copyright (c) 2022 Skyflow
*/

import XCTest
@testable import SkyflowFlowVault
@testable import SkyflowCore

final class skyflow_iOS_cvvMockTests: XCTestCase {

    // MARK: - CVVMockGenerator

    func testGeneratedMockMatchesRequestedLength() {
        for length in [3, 4] {
            let mock = CVVMockGenerator.generateMockCVV(length: length, actualValue: "000")
            XCTAssertEqual(mock.count, length)
        }
    }

    func testGeneratedMockIsNumeric() {
        let mock = CVVMockGenerator.generateMockCVV(length: 4, actualValue: "1234")
        XCTAssertNotNil(Int(mock))
    }

    func testGeneratedMockNeverEqualsActualValue() {
        // Run repeatedly since generation is random - none of the draws should ever match.
        for _ in 0..<200 {
            let mock = CVVMockGenerator.generateMockCVV(length: 3, actualValue: "123")
            XCTAssertNotEqual(mock, "123")
        }
    }

    func testGeneratedMockAllowsLeadingZeros() {
        // A 3-digit space has only 1000 possibilities; forcing actualValue to something that
        // can't collide keeps this deterministic while still exercising the "starts with 0" case
        // over many draws.
        var sawLeadingZero = false
        for _ in 0..<500 where !sawLeadingZero {
            let mock = CVVMockGenerator.generateMockCVV(length: 3, actualValue: "999")
            if mock.hasPrefix("0") {
                sawLeadingZero = true
            }
        }
        XCTAssertTrue(sawLeadingZero)
    }

    // MARK: - CVVTokenReplacer.captureCVVMap

    private func makeCVVElement(table: String, column: String, value: String, skyflowId: String? = nil) -> TextField {
        let input = CollectElementInput(tableName: table, column: column, type: .CVV, skyflowId: skyflowId)
        let field = TextField(input: input.data, options: CollectElementOptions().data, contextOptions: ContextOptions(), elements: [])
        field.actualValue = value
        return field
    }

    private func makeInputFieldElement(table: String, column: String, value: String) -> TextField {
        let input = CollectElementInput(tableName: table, column: column, type: .INPUT_FIELD)
        let field = TextField(input: input.data, options: CollectElementOptions().data, contextOptions: ContextOptions(), elements: [])
        field.actualValue = value
        return field
    }

    func testCaptureOnlyPicksUpCVVElements() {
        let cvv = makeCVVElement(table: "persons", column: "cvv", value: "123")
        let name = makeInputFieldElement(table: "persons", column: "name", value: "John")

        let map = CVVTokenReplacer.captureCVVMap(elements: [cvv, name])

        XCTAssertEqual(map.byTable["persons"]?["cvv"], "123")
        XCTAssertNil(map.byTable["persons"]?["name"])
    }

    func testCaptureKeysInsertsByTableAndUpdatesByRecordId() {
        let insertCVV = makeCVVElement(table: "persons", column: "cvv", value: "123")
        let updateCVV = makeCVVElement(table: "persons", column: "cvv", value: "456", skyflowId: "SID1")

        let map = CVVTokenReplacer.captureCVVMap(elements: [insertCVV, updateCVV])

        XCTAssertEqual(map.byTable["persons"]?["cvv"], "123")
        XCTAssertEqual(map.byRecordId["SID1"]?["cvv"], "456")
    }

    func testCaptureFirstElementWinsOnDuplicateColumn() {
        // Mirrors CollectRequestBuilder's own dedup rule (e.g. ElementValueMatchRule):
        // when two elements target the same column, only the first one's value reaches the vault.
        let first = makeCVVElement(table: "persons", column: "cvv", value: "111")
        let second = makeCVVElement(table: "persons", column: "cvv", value: "222")

        let map = CVVTokenReplacer.captureCVVMap(elements: [first, second])

        XCTAssertEqual(map.byTable["persons"]?["cvv"], "111")
    }

    func testCaptureStillCapturesEmptyValue() {
        // An optional CVV element left blank still submits "" to the vault and can get a real
        // token back - it must still be captured so that token gets masked too.
        let cvv = makeCVVElement(table: "persons", column: "cvv", value: "")
        let map = CVVTokenReplacer.captureCVVMap(elements: [cvv])
        XCTAssertEqual(map.byTable["persons"]?["cvv"], "")
    }

    func testReplaceFlatColumnWithEmptyEnteredValueBecomesEmptyString() {
        let cvvMap = CVVCaptureMap(byTable: ["persons": ["cvv": ""]], byRecordId: [:])
        let records: [[String: Any]] = [[
            "tableName": "persons",
            "fields": [
                "cvv": [["token": "real-token-for-empty-value", "tokenGroupName": "deterministic"]],
                "name": [["token": "name-token", "tokenGroupName": "deterministic"]]
            ]
        ]]

        let result = CVVTokenReplacer.replaceCVVTokens(in: records, cvvMap: cvvMap)
        let fields = result[0]["fields"] as! [String: Any]
        let cvvEntries = fields["cvv"] as! [[String: Any]]
        let nameEntries = fields["name"] as! [[String: Any]]

        // A real (long) vault token no longer leaks through unmasked just because the field
        // was left blank - it's replaced with "", never a generated mock (generating one for a
        // length-0 entered value would never terminate, see CVVMockGenerator's guard).
        XCTAssertEqual(cvvEntries[0]["token"] as! String, "")
        // Sibling column untouched.
        XCTAssertEqual(nameEntries[0]["token"] as! String, "name-token")
    }

    func testReplaceNestedColumnWithEmptyEnteredValueBecomesEmptyString() {
        let cvvMap = CVVCaptureMap(byTable: ["persons": ["address.pincode": ""]], byRecordId: [:])
        let records: [[String: Any]] = [[
            "tableName": "persons",
            "fields": [
                "address": [
                    ["token": "whole-column-token", "tokenGroupName": "deterministic"],
                    ["path": "pincode", "token": "real-pincode-token", "tokenGroupName": "deterministic"],
                    ["path": "city", "token": "city-token", "tokenGroupName": "deterministic"]
                ]
            ]
        ]]

        let result = CVVTokenReplacer.replaceCVVTokens(in: records, cvvMap: cvvMap)
        let addressEntries = (result[0]["fields"] as! [String: Any])["address"] as! [[String: Any]]

        let wholeColumn = addressEntries.first { $0["path"] == nil }!
        let pincode = addressEntries.first { $0["path"] as? String == "pincode" }!
        let city = addressEntries.first { $0["path"] as? String == "city" }!

        // Only the "pincode" leaf becomes "" - parent/sibling entries are untouched.
        XCTAssertEqual(pincode["token"] as! String, "")
        XCTAssertEqual(wholeColumn["token"] as! String, "whole-column-token")
        XCTAssertEqual(city["token"] as! String, "city-token")
    }

    func testGeneratedMockWithZeroLengthReturnsEmptyStringWithoutLooping() {
        // Guards against the hazard directly: length 0 with actualValue "" would make the
        // "regenerate until different" loop never terminate if this guard weren't there,
        // since every candidate is "" and "" always equals the empty actualValue.
        let mock = CVVMockGenerator.generateMockCVV(length: 0, actualValue: "")
        XCTAssertEqual(mock, "")
    }

    private func makePINElement(table: String, column: String, value: String) -> TextField {
        let input = CollectElementInput(tableName: table, column: column, type: .PIN)
        let field = TextField(input: input.data, options: CollectElementOptions().data, contextOptions: ContextOptions(), elements: [])
        field.actualValue = value
        return field
    }

    // A PIN element is never masked, even on a column literally named "pincode" (a postal-code
    // subfield, unrelated to ElementType.PIN) or sharing a table with a real CVV element.
    func testCaptureAndReplaceNeverTouchPINElements() {
        let cvv = makeCVVElement(table: "nested", column: "card.cvv", value: "123")
        let pin = makePINElement(table: "nested", column: "address.pincode", value: "5000")

        let map = CVVTokenReplacer.captureCVVMap(elements: [cvv, pin])
        XCTAssertNil(map.byTable["nested"]?["address.pincode"])
        XCTAssertEqual(map.byTable["nested"]?["card.cvv"], "123")

        let records: [[String: Any]] = [[
            "tableName": "nested",
            "fields": [
                "card": [["path": "cvv", "token": "real-cvv-token", "tokenGroupName": "deterministic"]],
                "address": [["path": "pincode", "token": "real-pincode-token", "tokenGroupName": "deterministic"]]
            ]
        ]]

        let result = CVVTokenReplacer.replaceCVVTokens(in: records, cvvMap: map)
        let fields = result[0]["fields"] as! [String: Any]
        let cardEntries = fields["card"] as! [[String: Any]]
        let addressEntries = fields["address"] as! [[String: Any]]

        XCTAssertNotEqual(cardEntries[0]["token"] as! String, "real-cvv-token")
        // PIN's "pincode" token is untouched.
        XCTAssertEqual(addressEntries[0]["token"] as! String, "real-pincode-token")
    }

    // MARK: - CVVTokenReplacer.replaceCVVTokens

    func testReplaceFlatColumnSingleTokenGroup() {
        let cvvMap = CVVCaptureMap(byTable: ["persons": ["cvv": "123"]], byRecordId: [:])
        let records: [[String: Any]] = [[
            "tableName": "persons",
            "skyflowID": "SID1",
            "fields": [
                "cvv": [["token": "real-token", "tokenGroupName": "deterministic"]],
                "name": [["token": "name-token", "tokenGroupName": "deterministic"]]
            ]
        ]]

        let result = CVVTokenReplacer.replaceCVVTokens(in: records, cvvMap: cvvMap)
        let fields = result[0]["fields"] as! [String: Any]
        let cvvEntries = fields["cvv"] as! [[String: Any]]
        let nameEntries = fields["name"] as! [[String: Any]]

        XCTAssertEqual(cvvEntries.count, 1)
        XCTAssertNotEqual(cvvEntries[0]["token"] as! String, "real-token")
        XCTAssertEqual((cvvEntries[0]["token"] as! String).count, 3)
        // Non-CVV column untouched.
        XCTAssertEqual(nameEntries[0]["token"] as! String, "name-token")
    }

    func testReplaceFlatColumnMultipleTokenGroups() {
        let cvvMap = CVVCaptureMap(byTable: ["persons": ["cvv": "1234"]], byRecordId: [:])
        let records: [[String: Any]] = [[
            "tableName": "persons",
            "fields": [
                "cvv": [
                    ["token": "det-token", "tokenGroupName": "deterministic"],
                    ["token": "nondet-token", "tokenGroupName": "nondeterministic"]
                ]
            ]
        ]]

        let result = CVVTokenReplacer.replaceCVVTokens(in: records, cvvMap: cvvMap)
        let cvvEntries = (result[0]["fields"] as! [String: Any])["cvv"] as! [[String: Any]]

        XCTAssertEqual(cvvEntries.count, 2)
        let mock1 = cvvEntries[0]["token"] as! String
        let mock2 = cvvEntries[1]["token"] as! String
        // Both token-group entries for the same column get the same mock.
        XCTAssertEqual(mock1, mock2)
        XCTAssertNotEqual(mock1, "1234")
    }

    func testReplaceNestedColumnOnlyTouchesMatchingPath() {
        let cvvMap = CVVCaptureMap(byTable: ["nested": ["address.pincode": "9876"]], byRecordId: [:])
        let records: [[String: Any]] = [[
            "tableName": "nested",
            "fields": [
                "address": [
                    ["token": "whole-column-token", "tokenGroupName": "deterministic"],
                    ["path": "pincode", "token": "pincode-token", "tokenGroupName": "deterministic"],
                    ["path": "city", "token": "city-token", "tokenGroupName": "deterministic"]
                ]
            ]
        ]]

        let result = CVVTokenReplacer.replaceCVVTokens(in: records, cvvMap: cvvMap)
        let addressEntries = (result[0]["fields"] as! [String: Any])["address"] as! [[String: Any]]

        let wholeColumn = addressEntries.first { $0["path"] == nil }!
        let pincode = addressEntries.first { $0["path"] as? String == "pincode" }!
        let city = addressEntries.first { $0["path"] as? String == "city" }!

        // Only the "pincode" subfield is mocked.
        XCTAssertEqual(wholeColumn["token"] as! String, "whole-column-token")
        XCTAssertNotEqual(pincode["token"] as! String, "pincode-token")
        XCTAssertEqual(city["token"] as! String, "city-token")
    }

    func testReplaceMatchesUpdateByRecordIdBeforeInsertByTable() {
        let cvvMap = CVVCaptureMap(byTable: ["persons": ["cvv": "111"]], byRecordId: ["SID1": ["cvv": "222"]])
        let records: [[String: Any]] = [[
            "tableName": "persons",
            "skyflowID": "SID1",
            "fields": ["cvv": [["token": "real-token", "tokenGroupName": "deterministic"]]]
        ]]

        let result = CVVTokenReplacer.replaceCVVTokens(in: records, cvvMap: cvvMap)
        let cvvEntries = (result[0]["fields"] as! [String: Any])["cvv"] as! [[String: Any]]

        // Matched via byRecordId (length of captured "222" is 3), not byTable's "111".
        XCTAssertEqual((cvvEntries[0]["token"] as! String).count, 3)
    }

    func testReplaceLeavesHashedDataAndErrorRecordsUntouched() {
        let cvvMap = CVVCaptureMap(byTable: ["persons": ["cvv": "123"]], byRecordId: [:])
        let records: [[String: Any]] = [
            [
                "tableName": "persons",
                "fields": ["cvv": [["token": "real-token", "tokenGroupName": "deterministic"]]],
                "hashedData": ["cvv": [["data": "hash", "hashName": "sha256"]]]
            ],
            [
                "error": "some error",
                "tableName": "persons"
            ]
        ]

        let result = CVVTokenReplacer.replaceCVVTokens(in: records, cvvMap: cvvMap)

        let hashedData = result[0]["hashedData"] as! [String: Any]
        let hashEntries = hashedData["cvv"] as! [[String: Any]]
        XCTAssertEqual(hashEntries[0]["data"] as! String, "hash")

        XCTAssertEqual(result[1]["error"] as! String, "some error")
        XCTAssertNil(result[1]["fields"])
    }

    func testReplaceIsNoOpWhenNoCVVCaptured() {
        let records: [[String: Any]] = [[
            "tableName": "persons",
            "fields": ["cvv": [["token": "real-token", "tokenGroupName": "deterministic"]]]
        ]]

        let result = CVVTokenReplacer.replaceCVVTokens(in: records, cvvMap: CVVCaptureMap())
        let cvvEntries = (result[0]["fields"] as! [String: Any])["cvv"] as! [[String: Any]]
        XCTAssertEqual(cvvEntries[0]["token"] as! String, "real-token")
    }

    // MARK: - CVVMaskingCallback

    func testMaskingCallbackMasksOnSuccessRecords() {
        let cvvMap = CVVCaptureMap(byTable: ["persons": ["cvv": "123"]], byRecordId: [:])
        let expectation = XCTestExpectation(description: "onSuccess forwarded")
        let demo = DemoAPICallback(expectation: expectation)
        let masking = CVVMaskingCallback(cvvMap: cvvMap, wrapping: demo)

        masking.onSuccess([
            "records": [[
                "tableName": "persons",
                "fields": ["cvv": [["token": "real-token", "tokenGroupName": "deterministic"]]]
            ]]
        ])

        wait(for: [expectation], timeout: 5.0)
        let records = demo.data["records"] as! [[String: Any]]
        let cvvEntries = (records[0]["fields"] as! [String: Any])["cvv"] as! [[String: Any]]
        XCTAssertNotEqual(cvvEntries[0]["token"] as! String, "real-token")
    }

    func testMaskingCallbackMasksPartialFailureRecords() {
        let cvvMap = CVVCaptureMap(byTable: ["persons": ["cvv": "123"]], byRecordId: [:])
        let expectation = XCTestExpectation(description: "onFailure forwarded")
        let demo = DemoAPICallback(expectation: expectation)
        let masking = CVVMaskingCallback(cvvMap: cvvMap, wrapping: demo)

        masking.onFailure([
            "records": [[
                "tableName": "persons",
                "fields": ["cvv": [["token": "real-token", "tokenGroupName": "deterministic"]]]
            ]],
            "errors": [["error": "some other record failed"]]
        ])

        wait(for: [expectation], timeout: 5.0)
        let records = demo.data["records"] as! [[String: Any]]
        let cvvEntries = (records[0]["fields"] as! [String: Any])["cvv"] as! [[String: Any]]
        XCTAssertNotEqual(cvvEntries[0]["token"] as! String, "real-token")
    }

    // Note: a true end-to-end test through CollectContainer.collect()/ComposableContainer.collect()
    // (real network dispatch) isn't reachable from a unit test here: FlowVaultCollectAPICallback
    // always builds a fresh URLSession(configuration: .default), and URLProtocol.registerClass
    // only reliably intercepts URLSession.shared, not ad-hoc .default sessions - confirmed by this
    // failing against the real network (github.com/.../example.org) rather than the mock handler.
    // Making that interceptable would require adding a test-only seam to production SDK code
    // (e.g. FlowVaultCollectAPICallback's injectable urlSessionConfiguration), which is out of
    // scope here. The wiring itself (cvvMap capture + CVVMaskingCallback insertion in
    // CollectContainer.swift/ComposableContainer.swift) is two lines per container and is
    // exercised for real via the NormalTesting sample app's CVV Mock Scenarios screen against a
    // live vault; the masking logic itself is fully covered above without needing the network.
}
