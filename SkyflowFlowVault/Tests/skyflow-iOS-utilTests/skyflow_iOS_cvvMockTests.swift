/*
 * Copyright (c) 2022 Skyflow
*/

import XCTest
@testable import SkyflowFlowVault
@testable import SkyflowCore

final class skyflow_iOS_cvvMockTests: XCTestCase {

    // MARK: - Helpers

    private func makeCVVElement(table: String, column: String, value: String, skyflowId: String? = nil, returnMockValue: Bool = true) -> TextField {
        let input = CollectElementInput(tableName: table, column: column, type: .CVV, skyflowId: skyflowId)
        let options = CollectElementOptions(returnMockValue: returnMockValue)
        let field = TextField(input: input.data, options: options.data, contextOptions: ContextOptions(), elements: [])
        field.actualValue = value
        return field
    }

    private func makeInputFieldElement(table: String, column: String, value: String) -> TextField {
        let input = CollectElementInput(tableName: table, column: column, type: .INPUT_FIELD)
        let field = TextField(input: input.data, options: CollectElementOptions().data, contextOptions: ContextOptions(), elements: [])
        field.actualValue = value
        return field
    }

    private func makePINElement(table: String, column: String, value: String) -> TextField {
        let input = CollectElementInput(tableName: table, column: column, type: .PIN)
        let field = TextField(input: input.data, options: CollectElementOptions().data, contextOptions: ContextOptions(), elements: [])
        field.actualValue = value
        return field
    }

    // MARK: - Hardcoded mock value

    func testMockValueForThreeDigitCVVIs817() {
        let cvv = makeCVVElement(table: "t", column: "cvv", value: "123")
        let map = CVVTokenReplacer.captureCVVMap(elements: [cvv])
        let records: [[String: Any]] = [[
            "tableName": "t",
            "fields": ["cvv": [["token": "real-token", "tokenGroupName": "deterministic"]]]
        ]]
        let result = CVVTokenReplacer.replaceCVVTokens(in: records, cvvMap: map)
        let token = ((result[0]["fields"] as! [String: Any])["cvv"] as! [[String: Any]])[0]["token"] as! String
        XCTAssertEqual(token, "817")
    }

    func testMockValueForFourDigitCVVIs8173() {
        let cvv = makeCVVElement(table: "t", column: "cvv", value: "1234")
        let map = CVVTokenReplacer.captureCVVMap(elements: [cvv])
        let records: [[String: Any]] = [[
            "tableName": "t",
            "fields": ["cvv": [["token": "real-token", "tokenGroupName": "deterministic"]]]
        ]]
        let result = CVVTokenReplacer.replaceCVVTokens(in: records, cvvMap: map)
        let token = ((result[0]["fields"] as! [String: Any])["cvv"] as! [[String: Any]])[0]["token"] as! String
        XCTAssertEqual(token, "8173")
    }

    func testMockValueForEmptyEnteredCVVIsEmptyString() {
        let cvv = makeCVVElement(table: "t", column: "cvv", value: "")
        let map = CVVTokenReplacer.captureCVVMap(elements: [cvv])
        let records: [[String: Any]] = [[
            "tableName": "t",
            "fields": ["cvv": [["token": "real-token", "tokenGroupName": "deterministic"]]]
        ]]
        let result = CVVTokenReplacer.replaceCVVTokens(in: records, cvvMap: map)
        let token = ((result[0]["fields"] as! [String: Any])["cvv"] as! [[String: Any]])[0]["token"] as! String
        XCTAssertEqual(token, "")
    }

    // MARK: - returnMockValue gate

    func testCaptureSkipsElementWithReturnMockValueFalse() {
        let enabled = makeCVVElement(table: "t", column: "cvv1", value: "123", returnMockValue: true)
        let disabled = makeCVVElement(table: "t", column: "cvv2", value: "456", returnMockValue: false)
        let map = CVVTokenReplacer.captureCVVMap(elements: [enabled, disabled])
        XCTAssertEqual(map.byTable["t"]?["cvv1"], "123")
        XCTAssertNil(map.byTable["t"]?["cvv2"])
    }

    func testReplaceIsNoOpWhenAllElementsHaveReturnMockValueFalse() {
        let cvv = makeCVVElement(table: "t", column: "cvv", value: "123", returnMockValue: false)
        let map = CVVTokenReplacer.captureCVVMap(elements: [cvv])
        XCTAssertTrue(map.isEmpty)

        let records: [[String: Any]] = [[
            "tableName": "t",
            "fields": ["cvv": [["token": "real-token", "tokenGroupName": "deterministic"]]]
        ]]
        let result = CVVTokenReplacer.replaceCVVTokens(in: records, cvvMap: map)
        let token = ((result[0]["fields"] as! [String: Any])["cvv"] as! [[String: Any]])[0]["token"] as! String
        XCTAssertEqual(token, "real-token")
    }

    // MARK: - CVVTokenReplacer.captureCVVMap

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
        let first = makeCVVElement(table: "persons", column: "cvv", value: "111")
        let second = makeCVVElement(table: "persons", column: "cvv", value: "222")

        let map = CVVTokenReplacer.captureCVVMap(elements: [first, second])

        XCTAssertEqual(map.byTable["persons"]?["cvv"], "111")
    }

    func testCaptureStillCapturesEmptyValue() {
        let cvv = makeCVVElement(table: "persons", column: "cvv", value: "")
        let map = CVVTokenReplacer.captureCVVMap(elements: [cvv])
        XCTAssertEqual(map.byTable["persons"]?["cvv"], "")
    }

    // MARK: - CVVTokenReplacer.replaceCVVTokens

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

        XCTAssertEqual(cvvEntries[0]["token"] as! String, "")
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

        XCTAssertEqual(pincode["token"] as! String, "")
        XCTAssertEqual(wholeColumn["token"] as! String, "whole-column-token")
        XCTAssertEqual(city["token"] as! String, "city-token")
    }

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

        XCTAssertEqual(cardEntries[0]["token"] as! String, "817")
        XCTAssertEqual(addressEntries[0]["token"] as! String, "real-pincode-token")
    }

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
        XCTAssertEqual(cvvEntries[0]["token"] as! String, "817")
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

        // Both token-group entries for the same column get the same hardcoded mock.
        XCTAssertEqual(cvvEntries[0]["token"] as! String, "8173")
        XCTAssertEqual(cvvEntries[1]["token"] as! String, "8173")
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

        XCTAssertEqual(wholeColumn["token"] as! String, "whole-column-token")
        // 4-digit entered → "8173"
        XCTAssertEqual(pincode["token"] as! String, "8173")
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

        // byRecordId captures "222" (3-digit) → mock is "817"
        XCTAssertEqual(cvvEntries[0]["token"] as! String, "817")
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
        XCTAssertEqual(cvvEntries[0]["token"] as! String, "817")
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
        XCTAssertEqual(cvvEntries[0]["token"] as! String, "817")
    }
}
