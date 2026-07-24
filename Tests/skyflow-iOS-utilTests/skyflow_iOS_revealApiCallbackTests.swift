/*
 * Copyright (c) 2022 Skyflow
*/

// Unit tests for the dormant v1 PDB RevealAPICallback (kept for potential future PDB reuse).

import XCTest
@testable import Skyflow

final class skyflow_iOS_revealApiCallbackTests: XCTestCase {
    var revealApiCallback: RevealAPICallback!
    var expectation: XCTestExpectation!
    var callback: DemoAPICallback!

    override func setUp() {
        self.expectation = XCTestExpectation()
        self.callback = DemoAPICallback(expectation: self.expectation)
        self.revealApiCallback = RevealAPICallback(
            callback: self.callback,
            apiClient: APIClient(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: DemoTokenProvider()),
            connectionUrl: "https://example.org/v1/vaults/vault",
            records: [RevealRequestRecord(token: "token1")],
            contextOptions: ContextOptions()
        )
    }

    func testGetRequestSession() {
        let (request, _) = self.revealApiCallback.getRequestSession()

        XCTAssertEqual(request.url?.absoluteString, "https://example.org/v1/vaults/vault/detokenize")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.allHTTPHeaderFields?["Content-Type"], "application/json; utf-8")
        XCTAssertEqual(request.allHTTPHeaderFields?["Accept"], "application/json")
        XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer ")
    }

    func testGetRevealRequestBody() {
        do {
            let record = RevealRequestRecord(token: "abc123")
            let data = try self.revealApiCallback.getRevealRequestBody(record: record)
            let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
            let params = json["detokenizationParameters"] as! [[String: Any]]

            XCTAssertEqual(params.count, 1)
            XCTAssertEqual(params[0]["token"] as? String, "abc123")
            XCTAssertEqual(params[0]["redaction"] as? String, "PLAIN_TEXT")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testProcessResponseSuccess() {
        do {
            let record = RevealRequestRecord(token: "abc123")
            let responseDict = ["records": [["token": "abc123", "value": "revealed-value"]]]
            let data = try JSONSerialization.data(withJSONObject: responseDict)
            let httpResponse = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)

            let (success, failure) = try self.revealApiCallback.processResponse(record: record, data: data, response: httpResponse, error: nil)

            XCTAssertNil(failure)
            XCTAssertEqual(success?.token_id, "abc123")
            XCTAssertEqual(success?.value, "revealed-value")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testProcessResponseBadStatusCode() {
        do {
            let record = RevealRequestRecord(token: "badtoken")
            let responseDict = ["error": ["message": "Invalid Token"]]
            let data = try JSONSerialization.data(withJSONObject: responseDict)
            let httpResponse = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 404, httpVersion: "1.1", headerFields: ["x-request-id": "RID"])

            let (success, failure) = try self.revealApiCallback.processResponse(record: record, data: data, response: httpResponse, error: nil)

            XCTAssertNil(success)
            XCTAssertEqual(failure?.id, "badtoken")
            XCTAssertEqual(failure?.error.localizedDescription, "Invalid Token - request-id: RID")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testProcessResponseNetworkError() {
        let record = RevealRequestRecord(token: "abc123")
        let networkError = NSError(domain: "NSURLErrorDomain", code: -1009, userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."])

        do {
            _ = try self.revealApiCallback.processResponse(record: record, data: nil, response: nil, error: networkError)
            XCTFail("Should throw on a connection-level error")
        } catch {
            XCTAssertEqual((error as NSError).code, -1009)
        }
    }

    func testHandleCallbacksAllSuccess() {
        let success = [RevealSuccessRecord(token_id: "t1", value: "v1")]

        self.revealApiCallback.handleCallbacks(success: success, failure: [], isSuccess: true, errorObject: nil)
        wait(for: [self.expectation], timeout: 10.0)

        let records = self.callback.data["records"] as! [[String: Any]]
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0]["token"] as? String, "t1")
        XCTAssertEqual(records[0]["value"] as? String, "v1")
        XCTAssertNil(self.callback.data["errors"])
    }

    func testHandleCallbacksPartialFailure() {
        let success = [RevealSuccessRecord(token_id: "t1", value: "v1")]
        let failure = [RevealErrorRecord(id: "t2", error: NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invalid Token"]))]

        self.revealApiCallback.handleCallbacks(success: success, failure: failure, isSuccess: true, errorObject: nil)
        wait(for: [self.expectation], timeout: 10.0)

        let records = self.callback.data["records"] as! [[String: Any]]
        let errors = self.callback.data["errors"] as! [[String: Any]]
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0]["token"] as? String, "t2")
    }

    func testHandleCallbacksAllFailure() {
        let failure = [RevealErrorRecord(id: "t1", error: NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invalid Token"]))]

        self.revealApiCallback.handleCallbacks(success: [], failure: failure, isSuccess: true, errorObject: nil)
        wait(for: [self.expectation], timeout: 10.0)

        XCTAssertNil(self.callback.data["records"])
        let errors = self.callback.data["errors"] as! [[String: Any]]
        XCTAssertEqual(errors.count, 1)
    }

    func testHandleCallbacksTransportFailure() {
        // isSuccess = false represents a request-level (network) failure somewhere in the batch,
        // as opposed to a per-token error - it should route through callRevealOnFailure instead.
        let networkError = NSError(domain: "", code: -1009, userInfo: [NSLocalizedDescriptionKey: "offline"])

        self.revealApiCallback.handleCallbacks(success: [], failure: [], isSuccess: false, errorObject: networkError)
        wait(for: [self.expectation], timeout: 10.0)

        let errors = self.callback.data["errors"] as! [[String: NSError]]
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0]["error"]?.localizedDescription, "offline")
    }

    func testOnSuccessInvalidUrl() {
        self.revealApiCallback.connectionUrl = "invalid url"
        self.revealApiCallback.onSuccess("token")
        wait(for: [self.expectation], timeout: 20.0)

        let errors = self.callback.data["errors"] as! [[String: NSError]]
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0]["error"]?.localizedDescription, "unsupported URL")
    }

    func testOnFailureWrapsSwiftError() {
        let error = NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "boom"])

        self.revealApiCallback.onFailure(error)
        wait(for: [self.expectation], timeout: 10.0)

        let errors = self.callback.data["errors"] as! [[String: NSError]]
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0]["error"]?.localizedDescription, "boom")
    }

    func testOnFailurePassesThroughNonErrorValues() {
        let dict: [String: Any] = ["errors": [["error": "already a dict"]]]

        self.revealApiCallback.onFailure(dict)
        wait(for: [self.expectation], timeout: 10.0)

        XCTAssertNotNil(self.callback.data["errors"])
    }
}
