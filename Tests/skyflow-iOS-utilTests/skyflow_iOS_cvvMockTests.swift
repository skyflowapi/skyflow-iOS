/*
 * Copyright (c) 2022 Skyflow
*/

import XCTest
@testable import Skyflow

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
        let field = TextField(input: input, options: CollectElementOptions(), contextOptions: ContextOptions(), elements: [])
        field.actualValue = value
        return field
    }

    private func makeInputFieldElement(table: String, column: String, value: String) -> TextField {
        let input = CollectElementInput(tableName: table, column: column, type: .INPUT_FIELD)
        let field = TextField(input: input, options: CollectElementOptions(), contextOptions: ContextOptions(), elements: [])
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
        // Mirrors FlowVaultCollectRequestBody's own dedup rule (e.g. ElementValueMatchRule):
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

    func testReplaceUsesDefaultLengthForEmptyEnteredValue() {
        let cvvMap = CVVCaptureMap(byTable: ["persons": ["cvv": ""]], byRecordId: [:])
        let records: [[String: Any]] = [[
            "tableName": "persons",
            "fields": ["cvv": [["token": "real-token-for-empty-value", "tokenGroupName": "deterministic"]]]
        ]]

        let result = CVVTokenReplacer.replaceCVVTokens(in: records, cvvMap: cvvMap)
        let cvvEntries = (result[0]["fields"] as! [String: Any])["cvv"] as! [[String: Any]]
        let mock = cvvEntries[0]["token"] as! String

        // A real (long) vault token no longer leaks through unmasked just because the field
        // was left blank - it gets a mock-shaped token too, using the fixed default length.
        XCTAssertNotEqual(mock, "real-token-for-empty-value")
        XCTAssertEqual(mock.count, CVVTokenReplacer.defaultMockLengthForEmptyValue)
        XCTAssertNotNil(Int(mock))
    }

    private func makePINElement(table: String, column: String, value: String) -> TextField {
        let input = CollectElementInput(tableName: table, column: column, type: .PIN)
        let field = TextField(input: input, options: CollectElementOptions(), contextOptions: ContextOptions(), elements: [])
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

    // MARK: - End-to-end through CollectContainer.collect() / ComposableContainer.collect()

    // These exercise the actual wiring added to CollectContainer.swift/ComposableContainer.swift
    // (cvvMap capture + CVVMaskingCallback), not just the CVVTokenReplacer helpers in isolation.
    // FlowVaultCollectAPICallback always builds URLSession(configuration: .default), which - per
    // MockURLProtocol's own header comment - consults globally registered protocol classes, so
    // URLProtocol.registerClass is used here instead of the injectable-configuration approach
    // FlowVaultInsertAPICallback's tests use.

    // APIClient.isTokenValid() requires a JWT-shaped string with a future "exp" claim -
    // DemoTokenProvider's plain "dummy_token" fails that check, so collect() never gets past
    // the token-fetch step. This provider satisfies the shape check without hitting a real IDP.
    private class ValidJWTTokenProvider: TokenProvider {
        func getBearerToken(_ apiCallback: Callback) {
            let payload: [String: Any] = ["exp": Int(Date().timeIntervalSince1970) + 3600]
            let payloadData = try! JSONSerialization.data(withJSONObject: payload)
            apiCallback.onSuccess("header.\(payloadData.base64EncodedString()).signature")
        }
    }

    private func makeTestClient() -> Client {
        Skyflow.initialize(Configuration(
            vaultID: "test-vault",
            vaultURL: "https://example.org/",
            tokenProvider: ValidJWTTokenProvider(),
            options: Options(env: .DEV)
        ))
    }

    private func mount(_ element: TextField) -> UIWindow {
        let window = UIWindow()
        window.addSubview(element)
        return window
    }

    func testCollectContainerMasksCVVTokenOnInsert() {
        URLProtocol.registerClass(MockURLProtocol.self)
        defer { URLProtocol.unregisterClass(MockURLProtocol.self) }

        MockURLProtocol.requestHandler = { request in
            XCTAssertTrue(request.url!.absoluteString.contains("v2/records/insert"))
            let body: [String: Any] = ["records": [[
                "skyflowID": "SID1",
                "tableName": "persons",
                "tokens": [
                    "cvv": [["token": "real-cvv-token", "tokenGroupName": "deterministic"]],
                    "name": [["token": "real-name-token", "tokenGroupName": "deterministic"]]
                ],
                "httpCode": 200
            ]]]
            let data = try! JSONSerialization.data(withJSONObject: body)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
            return (response, data)
        }

        let client = makeTestClient()
        let container = client.container(type: ContainerType.COLLECT, options: nil)

        let cvvElement = container?.create(input: CollectElementInput(tableName: "persons", column: "cvv", type: .CVV),
                                            options: CollectElementOptions(required: false))
        let nameElement = container?.create(input: CollectElementInput(tableName: "persons", column: "name", type: .INPUT_FIELD),
                                             options: CollectElementOptions(required: false))
        let window = mount(cvvElement!)
        window.addSubview(nameElement!)
        cvvElement?.actualValue = "733"
        nameElement?.actualValue = "John"

        let expectation = XCTestExpectation(description: "collect() returns masked CVV token")
        let demo = DemoAPICallback(expectation: expectation)
        container?.collect(callback: demo.asCollectCallback)

        wait(for: [expectation], timeout: 10.0)

        guard let response = demo.collectResponse else {
            XCTFail("Expected a CollectResponse, got receivedResponse=\(demo.receivedResponse) data=\(demo.data)")
            return
        }
        let record = response.records[0]
        let cvvEntries = record.tokens?["cvv"] as! [[String: Any]]
        let nameEntries = record.tokens?["name"] as! [[String: Any]]

        XCTAssertNotEqual(cvvEntries[0]["token"] as! String, "real-cvv-token")
        XCTAssertEqual((cvvEntries[0]["token"] as! String).count, 3)
        // Non-CVV column reaches the app unchanged.
        XCTAssertEqual(nameEntries[0]["token"] as! String, "real-name-token")
    }

    func testCollectContainerMasksCVVTokenOnUpdate() {
        URLProtocol.registerClass(MockURLProtocol.self)
        defer { URLProtocol.unregisterClass(MockURLProtocol.self) }

        MockURLProtocol.requestHandler = { request in
            XCTAssertTrue(request.url!.absoluteString.contains("v2/records/update"))
            let body: [String: Any] = ["records": [[
                "skyflowID": "SID1",
                "tableName": "persons",
                "tokens": ["cvv": [["token": "real-cvv-token", "tokenGroupName": "deterministic"]]],
                "httpCode": 200
            ]]]
            let data = try! JSONSerialization.data(withJSONObject: body)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
            return (response, data)
        }

        let client = makeTestClient()
        let container = client.container(type: ContainerType.COLLECT, options: nil)
        let cvvElement = container?.create(input: CollectElementInput(tableName: "persons", column: "cvv", type: .CVV, skyflowId: "SID1"),
                                            options: CollectElementOptions(required: false))
        _ = mount(cvvElement!)
        cvvElement?.actualValue = "1234"

        let expectation = XCTestExpectation(description: "collect() returns masked CVV token for update")
        let demo = DemoAPICallback(expectation: expectation)
        container?.collect(callback: demo.asCollectCallback)

        wait(for: [expectation], timeout: 10.0)

        guard let response = demo.collectResponse else {
            XCTFail("Expected a CollectResponse, got receivedResponse=\(demo.receivedResponse) data=\(demo.data)")
            return
        }
        let cvvEntries = response.records[0].tokens?["cvv"] as! [[String: Any]]
        XCTAssertNotEqual(cvvEntries[0]["token"] as! String, "real-cvv-token")
        XCTAssertEqual((cvvEntries[0]["token"] as! String).count, 4)
    }

    func testComposableContainerMasksCVVTokenOnInsert() {
        URLProtocol.registerClass(MockURLProtocol.self)
        defer { URLProtocol.unregisterClass(MockURLProtocol.self) }

        MockURLProtocol.requestHandler = { request in
            let body: [String: Any] = ["records": [[
                "skyflowID": "SID1",
                "tableName": "persons",
                "tokens": ["cvv": [["token": "real-cvv-token", "tokenGroupName": "deterministic"]]],
                "httpCode": 200
            ]]]
            let data = try! JSONSerialization.data(withJSONObject: body)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
            return (response, data)
        }

        let client = makeTestClient()
        let container = client.container(type: ContainerType.COMPOSABLE, options: nil)
        let cvvElement = container?.create(input: CollectElementInput(tableName: "persons", column: "cvv", type: .CVV),
                                            options: CollectElementOptions(required: false))
        _ = mount(cvvElement!)
        cvvElement?.actualValue = "429"

        let expectation = XCTestExpectation(description: "composable collect() returns masked CVV token")
        let demo = DemoAPICallback(expectation: expectation)
        container?.collect(callback: demo.asCollectCallback)

        wait(for: [expectation], timeout: 10.0)

        guard let response = demo.collectResponse else {
            XCTFail("Expected a CollectResponse, got receivedResponse=\(demo.receivedResponse) data=\(demo.data)")
            return
        }
        let cvvEntries = response.records[0].tokens?["cvv"] as! [[String: Any]]
        XCTAssertNotEqual(cvvEntries[0]["token"] as! String, "real-cvv-token")
        XCTAssertEqual((cvvEntries[0]["token"] as! String).count, 3)
    }
}
