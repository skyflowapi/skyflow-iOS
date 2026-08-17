/*
 * Copyright (c) 2022 Skyflow
*/

// Branch coverage for CollectAPICallback: the onSuccess insert/update
// orchestration (driven with unresolvable/invalid URLs so no real vault is
// needed) and the response-processing helpers called directly with
// constructed HTTPURLResponse + Data.

import XCTest
@testable import Skyflow
@testable import SkyflowCore

final class skyflow_iOS_legacyCollectApiCallbackCoverageTests: XCTestCase {

    private let insertRecords: [String: Any] = ["records": [["table": "persons", "fields": ["name": "john"]]]]

    private func makeCallback(records: [String: Any], vaultURL: String,
                              tokens: Bool = false, clientCallback: Callback) -> CollectAPICallback {
        return CollectAPICallback(
            callback: clientCallback,
            apiClient: APIClient(vaultID: "vault_id", vaultURL: vaultURL, tokenProvider: DemoTokenProvider()),
            records: records,
            options: ICOptions(tokens: tokens),
            contextOptions: ContextOptions())
    }

    private func response(status: Int, headers: [String: String]? = nil) -> HTTPURLResponse {
        return HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: status,
                               httpVersion: nil, headerFields: headers)!
    }

    // MARK: - onSuccess orchestration

    func testOnSuccessInsertWithMalformedVaultURLReportsErrors() {
        // iOS 17+ URL(string:) percent-encodes the invalid characters, so the request
        // proceeds and fails at the network layer; the failure still surfaces as errors.
        let expectation = XCTestExpectation(description: "malformed vault URL should fail")
        let callback = DemoAPICallback(expectation: expectation)
        let apiCallback = makeCallback(records: insertRecords, vaultURL: "invalid url", clientCallback: callback)

        apiCallback.onSuccess("token")

        wait(for: [expectation], timeout: 20.0)
        XCTAssertNotNil(callback.data["errors"])
    }

    func testOnSuccessInsertWithUnreachableHostMergesIntoErrors() {
        let expectation = XCTestExpectation(description: "unreachable host should merge into errors")
        let callback = DemoAPICallback(expectation: expectation)
        let apiCallback = makeCallback(records: insertRecords, vaultURL: "https://vault.skyflow.invalid/",
                                       clientCallback: callback)

        apiCallback.onSuccess("token")

        wait(for: [expectation], timeout: 20.0)
        XCTAssertNotNil(callback.data["errors"])
    }

    func testOnSuccessUpdateWithUnreachableHostMergesIntoErrors() {
        let records: [String: Any] = ["update": [
            "key1": ["table": "persons", "skyflowID": "sid-1", "fields": ["name": "john"]]
        ]]
        let expectation = XCTestExpectation(description: "unreachable update host should merge into errors")
        let callback = DemoAPICallback(expectation: expectation)
        let apiCallback = makeCallback(records: records, vaultURL: "https://vault.skyflow.invalid/",
                                       clientCallback: callback)

        apiCallback.onSuccess("token")

        wait(for: [expectation], timeout: 20.0)
        XCTAssertNotNil(callback.data["errors"])
    }

    func testOnSuccessUpdateRecordMissingSkyflowIdIsSkipped() {
        let records: [String: Any] = ["update": ["key1": ["table": "persons"]]]
        let expectation = XCTestExpectation(description: "update entry without skyflowID should be skipped")
        let callback = DemoAPICallback(expectation: expectation)
        let apiCallback = makeCallback(records: records, vaultURL: "https://vault.skyflow.invalid/",
                                       clientCallback: callback)

        apiCallback.onSuccess("token")

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual((callback.data["errors"] as? [Any])?.count, 0)
    }

    func testOnSuccessUpdateRecordWithUnencodableTableReportsInvalidUrl() {
        let records: [String: Any] = ["update": [
            "key1": ["table": "bad table", "skyflowID": "sid 1", "fields": ["name": "john"]]
        ]]
        let expectation = XCTestExpectation(description: "update entry producing an invalid URL should error")
        let callback = DemoAPICallback(expectation: expectation)
        let apiCallback = makeCallback(records: records, vaultURL: "https://vault.skyflow.invalid/",
                                       clientCallback: callback)

        apiCallback.onSuccess("token")

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual((callback.data["errors"] as? [Any])?.count, 1)
    }

    // MARK: - processUpdateResponse

    private var directCallback: CollectAPICallback {
        makeCallback(records: insertRecords, vaultURL: "https://example.org/",
                     clientCallback: DemoAPICallback(expectation: XCTestExpectation()))
    }

    func testProcessUpdateResponseWithTokensBuildsFieldsRecord() throws {
        let apiCallback = makeCallback(records: insertRecords, vaultURL: "https://example.org/",
                                       tokens: true,
                                       clientCallback: DemoAPICallback(expectation: XCTestExpectation()))
        let data = try JSONSerialization.data(withJSONObject: ["skyflow_id": "sid-1", "tokens": ["card": "tok-1"]])

        let result = try apiCallback.processUpdateResponse(data: data, response: response(status: 200),
                                                           error: nil, table: "persons")

        let record = (result["records"] as! [[String: Any]])[0]
        let fields = record["fields"] as! [String: Any]
        XCTAssertEqual(fields["card"] as? String, "tok-1")
        XCTAssertEqual(fields["skyflow_id"] as? String, "sid-1")
        XCTAssertEqual(record["table"] as? String, "persons")
    }

    func testProcessUpdateResponseWithoutTokensAndNumericSkyflowId() throws {
        let data = try JSONSerialization.data(withJSONObject: ["skyflow_id": 123])

        let result = try directCallback.processUpdateResponse(data: data, response: response(status: 200),
                                                              error: nil, table: "persons")

        let record = (result["records"] as! [[String: Any]])[0]
        XCTAssertEqual(record["skyflow_id"] as? String, "123")
    }

    func testProcessUpdateResponseWithNilDataReturnsEmptyRecords() throws {
        let result = try directCallback.processUpdateResponse(data: nil, response: response(status: 200),
                                                              error: nil, table: "persons")

        XCTAssertEqual((result["records"] as? [Any])?.count, 0)
    }

    func testProcessUpdateResponseBadStatusIncludesRequestId() throws {
        let data = try JSONSerialization.data(withJSONObject: ["error": ["message": "update failed"]])

        let result = try directCallback.processUpdateResponse(
            data: data, response: response(status: 400, headers: ["x-request-id": "rid-1"]),
            error: nil, table: "persons")

        let error = result["error"] as! [String: Any]
        XCTAssertTrue((error["message"] as! String).contains("update failed"))
        XCTAssertTrue((error["message"] as! String).contains("rid-1"))
        XCTAssertEqual(error["code"] as? Int, 400)
    }

    func testProcessUpdateResponseBadStatusWithNonJsonBody() throws {
        let result = try directCallback.processUpdateResponse(
            data: Data("not json".utf8), response: response(status: 500), error: nil, table: "persons")

        let error = result["error"] as! [String: Any]
        XCTAssertEqual(error["message"] as? String, "not json")
        XCTAssertEqual(error["code"] as? Int, 500)
    }

    // MARK: - processResponse / getCollectResponseBody

    func testProcessResponseBadStatusWithNonJsonBody() throws {
        let result = try directCallback.processResponse(data: Data("boom".utf8),
                                                        response: response(status: 502), error: nil)

        let error = result["error"] as! [String: Any]
        XCTAssertEqual(error["message"] as? String, "boom")
        XCTAssertEqual(error["code"] as? Int, 502)
    }

    func testProcessResponseWithNilDataReturnsEmptyDictionary() throws {
        let result = try directCallback.processResponse(data: nil, response: response(status: 200), error: nil)

        XCTAssertTrue(result.isEmpty)
    }

    func testProcessResponseSuccessParsesBatchBody() throws {
        let body: [String: Any] = ["responses": [["records": [["skyflow_id": "sid-1"]]]]]
        let data = try JSONSerialization.data(withJSONObject: body)

        let result = try directCallback.processResponse(data: data, response: response(status: 200), error: nil)

        let record = (result["records"] as! [[String: Any]])[0]
        XCTAssertEqual(record["skyflow_id"] as? String, "sid-1")
        XCTAssertEqual(record["table"] as? String, "persons")
    }

    func testGetCollectResponseBodyWithTokensMapsFieldsAndSkyflowId() throws {
        let apiCallback = makeCallback(records: insertRecords, vaultURL: "https://example.org/",
                                       tokens: true,
                                       clientCallback: DemoAPICallback(expectation: XCTestExpectation()))
        let body: [String: Any] = ["responses": [
            ["records": [["skyflow_id": "sid-1"]]],
            ["fields": ["card": "tok-1"]]
        ]]
        let data = try JSONSerialization.data(withJSONObject: body)

        let result = try apiCallback.getCollectResponseBody(data: data)

        let record = (result["records"] as! [[String: Any]])[0]
        let fields = record["fields"] as! [String: Any]
        XCTAssertEqual(fields["card"] as? String, "tok-1")
        XCTAssertEqual(fields["skyflow_id"] as? String, "sid-1")
    }
}
