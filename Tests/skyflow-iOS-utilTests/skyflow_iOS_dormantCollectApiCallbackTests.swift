/*
 * Copyright (c) 2022 Skyflow
*/

// Unit tests for the dormant v1 PDB CollectAPICallback/InsertAPICallback (kept for potential
// future PDB reuse).

import XCTest
@testable import Skyflow

final class skyflow_iOS_dormantCollectApiCallbackTests: XCTestCase {
    var collectCallback: CollectAPICallback!
    var defaultRecord: [String: Any] = ["records": [["table": "table", "fields": ["field": "value"]]]]

    override func setUp() {
        self.collectCallback = CollectAPICallback(
            callback: DemoAPICallback(expectation: XCTestExpectation()),
            apiClient: APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
            records: defaultRecord,
            options: ICOptions(tokens: false),
            contextOptions: ContextOptions()
        )
    }

    func testBuildFieldsDict() {
        let dict = ["key": "value", "nested": ["key": "value"]] as [String: Any]
        let result = self.collectCallback.buildFieldsDict(dict: dict)
        XCTAssertEqual(dict["key"] as! String, result["key"] as! String)
        XCTAssertEqual(dict["nested"] as! [String: String], result["nested"] as! [String: String])
    }

    func testOnSuccessWithNoInsertAndNoUpdateRecords() {
        // No network call should be made at all when there's nothing to insert or update.
        let expectation = XCTestExpectation(description: "Empty batch should succeed with an empty response")
        let callback = DemoAPICallback(expectation: expectation)
        let emptyCallback = CollectAPICallback(
            callback: callback,
            apiClient: APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
            records: ["records": []],
            options: ICOptions(tokens: false),
            contextOptions: ContextOptions()
        )

        emptyCallback.onSuccess("token")
        wait(for: [expectation], timeout: 10.0)

        XCTAssertTrue(callback.data.isEmpty)
    }

    func testGetRequestSession() {
        let url = URL(string: "https://example.org")!
        do {
            let (request, session) = try self.collectCallback.getRequestSession(url: url)
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer ")
            let body = try JSONSerialization.jsonObject(with: request.httpBody!, options: .allowFragments) as! [String: Any]
            let records = body["records"] as! [[String: Any]]
            XCTAssertEqual(records.count, 1)
            XCTAssertEqual(records[0]["tableName"] as? String, "table")
            XCTAssertNotNil(session)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testProcessResponseNetworkError() {
        let networkError = NSError(domain: "NSURLErrorDomain", code: -1009, userInfo: [NSLocalizedDescriptionKey: "offline"])
        do {
            let result = try self.collectCallback.processResponse(data: nil, response: nil, error: networkError)
            let errorDict = result["error"] as! [String: Any]
            XCTAssertEqual(errorDict["message"] as? String, "offline")
        } catch {
            XCTFail("Should not throw for a connection-level error: \(error)")
        }
    }

    func testProcessResponseBadStatusCode() {
        let responseDict = ["error": ["message": "Internal Server Error"]]
        do {
            let data = try JSONSerialization.data(withJSONObject: responseDict, options: .fragmentsAllowed)
            let httpResponse = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 500, httpVersion: "1.1", headerFields: ["x-request-id": "RID"])
            let result = try self.collectCallback.processResponse(data: data, response: httpResponse, error: nil)
            let errorDict = result["error"] as! [String: Any]
            XCTAssertEqual(errorDict["message"] as? String, "Internal Server Error - request-id: RID")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testGetCollectResponseBody() {
        // Old v1 gateway-batch response shape: {"responses": [{"records": [{"skyflow_id": ...}]}]}
        // getCollectResponseBody walks self.records["records"] (the INPUT records), reading the
        // matching entry out of the responses array at the same index - so the input record count
        // must match, not the responses array's own length.
        let twoRecordCallback = CollectAPICallback(
            callback: DemoAPICallback(expectation: XCTestExpectation()),
            apiClient: APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
            records: ["records": [["table": "table1", "fields": ["field": "value1"]], ["table": "table2", "fields": ["field": "value2"]]]],
            options: ICOptions(tokens: false),
            contextOptions: ContextOptions()
        )
        let responseDict: [String: Any] = [
            "responses": [
                ["records": [["skyflow_id": "SID1"]]],
                ["records": [["skyflow_id": "SID2"]]]
            ]
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: responseDict, options: .fragmentsAllowed)
            let result = try twoRecordCallback.getCollectResponseBody(data: data)
            let records = result["records"] as! [[String: Any]]
            XCTAssertEqual(records.count, 2)
            XCTAssertEqual(records[0]["table"] as? String, "table1")
            XCTAssertEqual(records[0]["skyflow_id"] as? String, "SID1")
            XCTAssertEqual(records[1]["table"] as? String, "table2")
            XCTAssertEqual(records[1]["skyflow_id"] as? String, "SID2")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testProcessUpdateResponseSuccess() {
        let responseDict: [String: Any] = ["skyflow_id": "SID1"]
        do {
            let data = try JSONSerialization.data(withJSONObject: responseDict, options: .fragmentsAllowed)
            let httpResponse = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)
            let result = try self.collectCallback.processUpdateResponse(data: data, response: httpResponse, error: nil, table: "table")
            let records = result["records"] as! [[String: Any]]
            XCTAssertEqual(records.count, 1)
            XCTAssertEqual(records[0]["skyflow_id"] as? String, "SID1")
            XCTAssertEqual(records[0]["table"] as? String, "table")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testProcessUpdateResponseBadStatusCode() {
        let responseDict = ["error": ["message": "Record not found"]]
        do {
            let data = try JSONSerialization.data(withJSONObject: responseDict, options: .fragmentsAllowed)
            let httpResponse = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 404, httpVersion: "1.1", headerFields: nil)
            let result = try self.collectCallback.processUpdateResponse(data: data, response: httpResponse, error: nil, table: "table")
            let errorDict = result["error"] as! [String: Any]
            XCTAssertEqual(errorDict["message"] as? String, "Record not found")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testOnFailure() {
        let expectation = XCTestExpectation()
        let callback = DemoAPICallback(expectation: expectation)
        self.collectCallback.callback = callback

        self.collectCallback.onFailure(["errors": [["error": "boom"]]])
        wait(for: [expectation], timeout: 10.0)

        XCTAssertNotNil(callback.data["errors"])
    }
}

final class skyflow_iOS_dormantInsertApiCallbackTests: XCTestCase {
    var insertCallback: InsertAPICallback!
    var defaultRecord: [String: Any] = ["records": [["table": "table", "fields": ["field": "value"]]]]

    override func setUp() {
        self.insertCallback = InsertAPICallback(
            callback: DemoAPICallback(expectation: XCTestExpectation()),
            apiClient: APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
            records: defaultRecord,
            options: ICOptions(tokens: false),
            contextOptions: ContextOptions()
        )
    }

    func testBuildFieldsDict() {
        let dict = ["key": "value", "nested": ["key": "value"]] as [String: Any]
        let result = self.insertCallback.buildFieldsDict(dict: dict)
        XCTAssertEqual(dict["key"] as! String, result["key"] as! String)
        XCTAssertEqual(dict["nested"] as! [String: String], result["nested"] as! [String: String])
    }

    func testGetRequestSession() {
        let url = URL(string: "https://example.org")!
        do {
            let (request, session) = try self.insertCallback.getRequestSession(url: url)
            XCTAssertEqual(request.httpMethod, "POST")
            XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer ")
            let body = try JSONSerialization.jsonObject(with: request.httpBody!, options: .allowFragments) as! [String: Any]
            let records = body["records"] as! [[String: Any]]
            XCTAssertEqual(records.count, 1)
            XCTAssertEqual(records[0]["tableName"] as? String, "table")
            XCTAssertNotNil(session)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testProcessResponseNetworkErrorThrows() {
        let networkError = NSError(domain: "NSURLErrorDomain", code: -1009, userInfo: [NSLocalizedDescriptionKey: "offline"])
        do {
            _ = try self.insertCallback.processResponse(data: nil, response: nil, error: networkError)
            XCTFail("Should throw on a connection-level error")
        } catch {
            XCTAssertEqual((error as NSError).code, -1009)
        }
    }

    func testProcessResponseBadStatusCodeThrows() {
        let responseDict = ["error": ["message": "Internal Server Error"]]
        do {
            let data = try JSONSerialization.data(withJSONObject: responseDict, options: .fragmentsAllowed)
            let httpResponse = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 500, httpVersion: "1.1", headerFields: ["x-request-id": "RID"])
            _ = try self.insertCallback.processResponse(data: data, response: httpResponse, error: nil)
            XCTFail("Should throw on a bad status code")
        } catch {
            XCTAssertEqual(error.localizedDescription, "Internal Server Error - request-id: RID")
        }
    }

    func testGetCollectResponseBody() {
        let responseDict: [String: Any] = [
            "responses": [
                ["records": [["skyflow_id": "SID1"]]]
            ]
        ]
        do {
            let data = try JSONSerialization.data(withJSONObject: responseDict, options: .fragmentsAllowed)
            let result = try self.insertCallback.getCollectResponseBody(data: data)
            let records = result["records"] as! [[String: Any]]
            XCTAssertEqual(records.count, 1)
            XCTAssertEqual(records[0]["table"] as? String, "table")
            XCTAssertEqual(records[0]["skyflow_id"] as? String, "SID1")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testOnFailure() {
        let expectation = XCTestExpectation()
        let callback = DemoAPICallback(expectation: expectation)
        self.insertCallback.callback = callback

        self.insertCallback.onFailure(["errors": [["error": "boom"]]])
        wait(for: [expectation], timeout: 10.0)

        XCTAssertNotNil(callback.data["errors"])
    }
}
