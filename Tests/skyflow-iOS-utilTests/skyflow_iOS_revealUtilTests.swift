/*
 * Copyright (c) 2022 Skyflow
*/

// swiftlint:disable file_length
import XCTest
@testable import Skyflow

// swiftlint:disable:next type_body_length
final class skyflow_iOS_revealUtilTests: XCTestCase {
    
    var revealApiCallback: FlowVaultRevealAPICallback! = nil
    var revealValueCallback: RevealValueCallback! = nil
    var expectation: XCTestExpectation! = nil
    var callback: DemoAPICallback! = nil
    
    var client: Client = Client(Configuration(tokenProvider: DemoTokenProvider()))
    var container: Container<RevealContainer>! = nil
    
    override func setUp() {
        self.expectation = XCTestExpectation()
        self.callback = DemoAPICallback(expectation: self.expectation)
        self.revealApiCallback = FlowVaultRevealAPICallback(callback: self.callback,
                                                   apiClient: APIClient(vaultID: "", vaultURL: "", tokenProvider: DemoTokenProvider()),
                                                   connectionUrl: "",
                                                   records: [],
                                                   contextOptions: ContextOptions())
        self.revealValueCallback = RevealValueCallback(callback: self.callback, revealElements: [], contextOptions: ContextOptions())
        self.container = client.container(type: ContainerType.REVEAL)
    }
    
    func waitForUIUpdates() {
        
        let expectation = self.expectation(description: "Test")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
   func testOnSuccessInvalidUrl() {
       self.revealApiCallback.connectionUrl = "invalid url"
       let record = RevealRequestRecord(token: "token")
       self.revealApiCallback.records = [record]
       self.revealApiCallback.onSuccess("token")
       wait(for: [self.expectation], timeout: 10.0)
       let errors = callback.data["errors"] as! [[String: NSError]]
       XCTAssertEqual(errors.count, 1)
       XCTAssertEqual(errors[0]["error"]?.localizedDescription, "unsupported URL")
   }

    func testGetRequestSession() {
        let url = URL(string: "https://www.example.org")!

        do {
            let (request, session) = try self.revealApiCallback.getRequestSession(url: url)
            XCTAssertEqual(request.url?.absoluteString, "https://www.example.org")
            XCTAssertEqual(request.allHTTPHeaderFields!["Content-Type"], "application/json")
            XCTAssertEqual(request.allHTTPHeaderFields!["Accept"], "application/json")
            XCTAssertEqual(request.allHTTPHeaderFields!["Authorization"], "Bearer ")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testConstructV2DetokenizeRequestBody() {
        self.revealApiCallback.records = [RevealRequestRecord(token: "token1"), RevealRequestRecord(token: "token2")]
        let result = FlowVaultDetokenizeRequestBody.createRequestBody(vaultID: "vault123", records: self.revealApiCallback.records)

        XCTAssertEqual(result["vaultID"] as! String, "vault123")
        XCTAssertEqual(result["tokens"] as! [String], ["token1", "token2"])
        XCTAssertNil(result["tokenGroupRedactions"])
    }

    func testConstructV2DetokenizeRequestBodyWithTokenGroupRedactions() {
        let records = [RevealRequestRecord(token: "token1")]
        let tokenGroupRedactions = [TokenGroupRedaction(tokenGroupName: "group1", redaction: "MASKED")]
        let result = FlowVaultDetokenizeRequestBody.createRequestBody(vaultID: "vault123", records: records, tokenGroupRedactions: tokenGroupRedactions)

        let redactions = result["tokenGroupRedactions"] as! [[String: Any]]
        XCTAssertEqual(redactions.count, 1)
        XCTAssertEqual(redactions[0]["tokenGroupName"] as? String, "group1")
        XCTAssertEqual(redactions[0]["redaction"] as? String, "MASKED")
    }

    func testProcessResponseError() {
        let revealedResponse = ["key": "value"]
        let serverError = NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "Internal Server Error"])
        do {
            let responseData = try JSONSerialization.data(withJSONObject: revealedResponse, options: .fragmentsAllowed)
            _ = try self.revealApiCallback.processResponse(data: responseData, response: nil, error: serverError)
            XCTFail("Not throwing on http error")
        } catch {
            XCTAssertEqual(error.localizedDescription, serverError.localizedDescription)
        }
    }

    func testProcessResponseBadCode() {
        let revealedResponse = ["error": ["message": "Internal Server Error"]]
        let httpResponse = HTTPURLResponse(url: URL(string: "https://www.example.org")!, statusCode: 500, httpVersion: "1.1", headerFields: ["x-request-id": "RID"])
        do {
            let responseData = try JSONSerialization.data(withJSONObject: revealedResponse, options: .fragmentsAllowed)
            _ = try self.revealApiCallback.processResponse(data: responseData, response: httpResponse, error: nil)
            XCTFail("Not throwing on http error")
        } catch {
            XCTAssertEqual(error.localizedDescription, "Internal Server Error - request-id: RID")
        }
    }

    func testProcessResponseSuccess() {
        let revealedResponse = ["response": [["token": "token", "value": "value"]]]
        let httpResponse = HTTPURLResponse(url: URL(string: "https://www.example.org")!, statusCode: 200, httpVersion: "1.1", headerFields: ["x-request-id": "RID"])
        do {
            let responseData = try JSONSerialization.data(withJSONObject: revealedResponse, options: .fragmentsAllowed)
            let response = try self.revealApiCallback.processResponse(data: responseData, response: httpResponse, error: nil)
            let records = response["records"] as! [[String: Any]]
            XCTAssertEqual(records.count, 1)
            XCTAssertEqual(records[0]["token"] as? String, "token")
            XCTAssertEqual(records[0]["value"] as? String, "value")
            XCTAssertNil(records[0]["error"])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testProcessResponseWithMetadataAndHttpCode() {
        let revealedResponse: [String: Any] = ["response": [
            ["token": "token", "value": "value", "httpCode": 200, "metadata": ["tableName": "table", "skyflowID": "SID"]]
        ]]
        let httpResponse = HTTPURLResponse(url: URL(string: "https://www.example.org")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        do {
            let responseData = try JSONSerialization.data(withJSONObject: revealedResponse, options: .fragmentsAllowed)
            let response = try self.revealApiCallback.processResponse(data: responseData, response: httpResponse, error: nil)
            let records = response["records"] as! [[String: Any]]

            XCTAssertEqual(records.count, 1)
            XCTAssertEqual(records[0]["httpCode"] as? Int, 200)
            let metadata = records[0]["metadata"] as! [String: Any]
            XCTAssertEqual(metadata["tableName"] as? String, "table")
            XCTAssertEqual(metadata["skyflowID"] as? String, "SID")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testProcessResponsePartialFailure() {
        let revealedResponse: [String: Any] = ["response": [
            ["token": "token1", "value": "value1"],
            ["token": "token2", "error": "Invalid Token", "httpCode": 400]
        ]]
        let httpResponse = HTTPURLResponse(url: URL(string: "https://www.example.org")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)
        do {
            let responseData = try JSONSerialization.data(withJSONObject: revealedResponse, options: .fragmentsAllowed)
            let response = try self.revealApiCallback.processResponse(data: responseData, response: httpResponse, error: nil)
            let records = response["records"] as! [[String: Any]]
            XCTAssertEqual(records.count, 2)
            XCTAssertEqual(records[0]["token"] as? String, "token1")
            XCTAssertNil(records[0]["error"])
            XCTAssertEqual(records[1]["token"] as? String, "token2")
            XCTAssertEqual(records[1]["error"] as? String, "Invalid Token")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testProcessResponseFullFailureWithNon2xxOuterStatus() {
        let revealedResponse: [String: Any] = ["response": [
            ["token": "dedwimm", "value": NSNull(), "tokenGroupName": NSNull(),
             "error": "Detokenize failed. Token dedwimm is invalid. Specify a valid token.",
             "httpCode": 404, "metadata": NSNull()],
            ["token": "femwdmm", "value": NSNull(), "tokenGroupName": NSNull(),
             "error": "Detokenize failed. Token femwdmm is invalid. Specify a valid token.",
             "httpCode": 404, "metadata": NSNull()]
        ]]
        let httpResponse = HTTPURLResponse(url: URL(string: "https://www.example.org")!, statusCode: 404, httpVersion: "1.1", headerFields: nil)
        do {
            let responseData = try JSONSerialization.data(withJSONObject: revealedResponse, options: .fragmentsAllowed)
            let response = try self.revealApiCallback.processResponse(data: responseData, response: httpResponse, error: nil)
            let records = response["records"] as! [[String: Any]]

            XCTAssertEqual(records.count, 2)
            XCTAssertEqual(records[0]["error"] as? String, "Detokenize failed. Token dedwimm is invalid. Specify a valid token.")
            XCTAssertEqual(records[0]["httpCode"] as? Int, 404)
        } catch {
            XCTFail("Full failure with 404 outer status should not throw: \(error)")
        }
    }

    func testProcessResponseInvalidTokenGroupError() {
        let revealedResponse: [String: Any] = ["error": [
            "grpc_code": 3,
            "http_code": 400,
            "message": "Detokenize failed. Token group no is invalid. Specify a valid token group.",
            "http_status": "Bad Request",
            "details": []
        ]]
        let httpResponse = HTTPURLResponse(url: URL(string: "https://www.example.org")!, statusCode: 400, httpVersion: "1.1", headerFields: nil)
        do {
            let responseData = try JSONSerialization.data(withJSONObject: revealedResponse, options: .fragmentsAllowed)
            _ = try self.revealApiCallback.processResponse(data: responseData, response: httpResponse, error: nil)
            XCTFail("Should throw on genuine top-level error (invalid token group)")
        } catch {
            XCTAssertEqual(error.localizedDescription, "Detokenize failed. Token group no is invalid. Specify a valid token group.")
        }
    }

    func testConstructV2DetokenizeRequestBodyPassesThroughDuplicateTokenGroupRedactions() {
        let records = [RevealRequestRecord(token: "token1")]
        let tokenGroupRedactions = [
            TokenGroupRedaction(tokenGroupName: "group1", redaction: "MASKED"),
            TokenGroupRedaction(tokenGroupName: "group1", redaction: "PLAIN_TEXT")
        ]
        let result = FlowVaultDetokenizeRequestBody.createRequestBody(vaultID: "vault123", records: records, tokenGroupRedactions: tokenGroupRedactions)

        let redactions = result["tokenGroupRedactions"] as! [[String: Any]]
        XCTAssertEqual(redactions.count, 2)
        XCTAssertEqual(redactions[0]["tokenGroupName"] as? String, "group1")
        XCTAssertEqual(redactions[0]["redaction"] as? String, "MASKED")
        XCTAssertEqual(redactions[1]["tokenGroupName"] as? String, "group1")
        XCTAssertEqual(redactions[1]["redaction"] as? String, "PLAIN_TEXT")
    }

    func testGetTokensToErrors() {
        let errors = [["token": "1234"], ["token": "4321"]]
        
        let result = self.revealValueCallback.getTokensToErrors(errors)
        
        XCTAssertEqual(result["1234"], "Invalid Token")
        XCTAssertEqual(result["4321"], "Invalid Token")
    }
    
    func testRevealValueOnSuccessPureSuccess() {
        // Every token revealed, zero errors - a genuine full-success scenario
        // (as opposed to the mixed success+error fixtures used elsewhere in this file).
        let token1 = "123"
        let token2 = "456"
        let response: [String: Any] = [
            "records": [
                ["token": token1, "value": "John"],
                ["token": token2, "value": "Doe"]
            ],
            "errors": []
        ]

        let element1 = self.container.create(input: RevealElementInput(token: token1, label: "first"), options: RevealElementOptions())
        let element2 = self.container.create(input: RevealElementInput(token: token2, label: "second"), options: RevealElementOptions())

        self.revealValueCallback.revealElements = [element1, element2]
        self.revealValueCallback.onSuccess(response)
        wait(for: [self.expectation], timeout: 20.0)
        waitForUIUpdates()

        let records = self.callback.data["records"] as! [[String: Any]]
        XCTAssertEqual(records.count, 2)
        XCTAssertTrue(records.allSatisfy { $0["error"] == nil })
        XCTAssertEqual(element1.actualValue, "John")
        XCTAssertEqual(element2.actualValue, "Doe")
        XCTAssertEqual(element1.errorMessage.text, nil)
        XCTAssertEqual(element2.errorMessage.text, nil)
    }

    func testRevealValueOnFailurePureFailure() {
        // Every token invalid, zero successes - a genuine full-failure scenario.
        let token1 = "123"
        let token2 = "456"
        let response: [String: Any] = [
            "records": [],
            "errors": [
                ["token": token1, "error": "Invalid Token"],
                ["token": token2, "error": "Invalid Token"]
            ]
        ]

        let element1 = self.container.create(input: RevealElementInput(token: token1, label: "first"))
        let element2 = self.container.create(input: RevealElementInput(token: token2, label: "second"))

        self.revealValueCallback.revealElements = [element1, element2]
        self.revealValueCallback.onFailure(response)
        wait(for: [self.expectation], timeout: 20.0)
        waitForUIUpdates()

        let errors = self.callback.data["records"] as! [[String: Any]]
        XCTAssertEqual(errors.count, 2)
        XCTAssertTrue(errors.allSatisfy { $0["error"] != nil })
        XCTAssertEqual(element1.actualValue, nil)
        XCTAssertEqual(element2.actualValue, nil)
        XCTAssertEqual(element1.errorMessage.text, "Invalid Token")
        XCTAssertEqual(element2.errorMessage.text, "Invalid Token")
    }

    func testRevealValueOnFailureNetworkErrorHasNoPerTokenErrors() {
        // Simulates what FlowVaultRevealAPICallback.callRevealOnFailure produces for a genuine
        // network/connection-level failure: no "records", and the error entry has no "token"
        // (since the failure isn't scoped to any specific token). Elements should not crash and
        // should not show a per-element error message (there's no token to match against), but
        // the client callback should still receive the error.
        let token1 = "123"
        let networkError = NSError(domain: "NSURLErrorDomain", code: -1009, userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."])
        let response: [String: Any] = [
            "errors": [["error": networkError]]
        ]

        let element1 = self.container.create(input: RevealElementInput(token: token1, label: "first"))
        self.revealValueCallback.revealElements = [element1]

        self.revealValueCallback.onFailure(response)
        wait(for: [self.expectation], timeout: 20.0)
        waitForUIUpdates()

        // Not scoped to any specific token, so it's delivered via onFailure (not folded into the
        // records array) rather than a per-record error.
        XCTAssertNil(self.callback.data["records"])
        XCTAssertEqual(self.callback.receivedResponse, "The Internet connection appears to be offline.")
        // No token to match this error against, so the element shows no inline error.
        XCTAssertEqual(element1.errorMessage.text, nil)
        XCTAssertEqual(element1.actualValue, nil)
    }

    func testRevealValueOnFailureWithNonDictionaryError() {
        // onFailure(_ error: Any) can in principle be called with something that isn't a
        // dictionary at all (the Callback protocol accepts Any). Must not crash, and should
        // report an empty response rather than propagating garbage.
        let element1 = self.container.create(input: RevealElementInput(token: "123", label: "first"))
        self.revealValueCallback.revealElements = [element1]

        self.revealValueCallback.onFailure("not a dictionary")
        wait(for: [self.expectation], timeout: 20.0)

        XCTAssertNil(self.callback.data["success"])
        XCTAssertNil(self.callback.data["errors"])
    }

    func testRevealValueOnSuccessWithNonDictionaryResponseBody() {
        // Same defensive case for onSuccess: a non-dictionary responseBody must not crash.
        let element1 = self.container.create(input: RevealElementInput(token: "123", label: "first"))
        self.revealValueCallback.revealElements = [element1]

        self.revealValueCallback.onSuccess(42)
        wait(for: [self.expectation], timeout: 20.0)
        waitForUIUpdates()

        XCTAssertNil(self.callback.data["success"])
        XCTAssertNil(self.callback.data["errors"])
        XCTAssertEqual(element1.actualValue, nil)
    }

    func testRevealValueOnSuccessSkipsMalformedRecords() {
        // A record missing "token" (or not a dictionary at all) must be skipped, not crash
        // the whole reveal for every other token in the same batch.
        let goodToken = "123"
        let response: [String: Any] = [
            "records": [
                ["token": goodToken, "value": "John"],
                ["value": "no token here"],
                "not even a dictionary",
                ["token": 42, "value": "token is not a String"]
            ],
            "errors": []
        ]

        let goodElement = self.container.create(input: RevealElementInput(token: goodToken, label: "good"), options: RevealElementOptions())
        self.revealValueCallback.revealElements = [goodElement]

        self.revealValueCallback.onSuccess(response)
        wait(for: [self.expectation], timeout: 20.0)
        waitForUIUpdates()

        let records = self.callback.data["records"] as! [[String: Any]]
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0]["token"] as? String, goodToken)
        XCTAssertEqual(goodElement.actualValue, "John")
    }

    func testRevealValueOnFailure() {
        let successToken = "123"
        let failureToken = "1234"
        let response = [
            "records": [["token": successToken, "value": "John"]],
            "errors": [["token": failureToken, "error": "Invalid Token"]]
        ]
        
        let successElement = self.container.create(input: RevealElementInput(token: successToken, label: "name"), options: RevealElementOptions())
        let failureElement = self.container.create(input: RevealElementInput(token: failureToken, label: "failed"))
        
        self.revealValueCallback.revealElements = [successElement, failureElement]
        
        self.revealValueCallback.onFailure(response)
        wait(for: [self.expectation], timeout: 20.0)
        waitForUIUpdates()
                
        let allRecords = self.callback.data["records"] as! [[String: String]]
        let errors = allRecords.filter { $0["error"] != nil }
        let records = allRecords.filter { $0["error"] == nil }
        
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0]["token"], failureToken)
        XCTAssertEqual(errors[0]["error"], "Invalid Token")
        XCTAssertEqual(failureElement.actualValue, nil)
        XCTAssertEqual(failureElement.errorMessage.text, "Invalid Token")
        
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0]["token"], successToken)
        XCTAssertEqual(successElement.actualValue, "John")
        XCTAssertEqual(successElement.errorMessage.text, nil)
    }
    
    func testRevealValueOnSuccess() {
        let successToken = "123"
        let failureToken = "1234"
        let response = [
            "records": [["token": successToken, "value": "John"], ["token": failureToken, "error": "Invalid Token"]]
        ]
        
        let successElement = self.container.create(input: RevealElementInput(token: successToken, label: "name"), options: RevealElementOptions())
        let failureElement = self.container.create(input: RevealElementInput(token: failureToken, label: "failed"))
        
        self.revealValueCallback.revealElements = [successElement, failureElement]
        
        self.revealValueCallback.onSuccess(response)
        wait(for: [self.expectation], timeout: 20.0)
        waitForUIUpdates()
        
        let allRecords = self.callback.data["records"] as! [[String: String]]
        let errors = allRecords.filter { $0["error"] != nil }
        let records = allRecords.filter { $0["error"] == nil }
        
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0]["token"], failureToken)
        XCTAssertEqual(errors[0]["error"], "Invalid Token")
        XCTAssertEqual(failureElement.actualValue, nil)
        XCTAssertEqual(failureElement.errorMessage.text, "Invalid Token")
        
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0]["token"], successToken)
        XCTAssertEqual(successElement.actualValue, "John")
        XCTAssertEqual(successElement.errorMessage.text, nil)
    }
    func testRevealValueOnSuccessFormat() { // reveal data value is equal to format length
        let successToken = "123"
        let failureToken = "1234"
        let response = [
            "records": [["token": successToken, "value": "4567890"], ["token": failureToken, "error": "Invalid Token"]]
        ]
        
        let successElement = self.container.create(input: RevealElementInput(token: successToken, label: "name"), options: RevealElementOptions(format: "XXX-XXX-X", translation: ["X": "[0-9]"]))
        let failureElement = self.container.create(input: RevealElementInput(token: failureToken, label: "failed"))
        
        self.revealValueCallback.revealElements = [successElement, failureElement]
        
        self.revealValueCallback.onSuccess(response)
        wait(for: [self.expectation], timeout: 20.0)
        waitForUIUpdates()
        
        let allRecords = self.callback.data["records"] as! [[String: String]]
        let errors = allRecords.filter { $0["error"] != nil }
        let records = allRecords.filter { $0["error"] == nil }
        
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0]["token"], failureToken)
        XCTAssertEqual(errors[0]["error"], "Invalid Token")
        XCTAssertEqual(failureElement.actualValue, nil)
        XCTAssertEqual(failureElement.errorMessage.text, "Invalid Token")
        
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0]["token"], successToken)
        XCTAssertEqual(successElement.actualValue, "4567890")
        XCTAssertEqual(successElement.errorMessage.text, nil)
        XCTAssertEqual(successElement.skyflowLabelView.label.secureText!, "456-789-0")

    }
    func testRevealValueOnSuccessFormatCase2() { //format length is greater than revealed data length
        let successToken = "123"
        let failureToken = "1234"
        let response = [
            "records": [["token": successToken, "value": "12345678"], ["token": failureToken, "error": "Invalid Token"]]
        ]
        
        let successElement = self.container.create(input: RevealElementInput(token: successToken, label: "name"), options: RevealElementOptions(format: "XXX-XXX-XXX", translation: ["X": "[0-9]"]))
        let failureElement = self.container.create(input: RevealElementInput(token: failureToken, label: "failed"))
        
        self.revealValueCallback.revealElements = [successElement, failureElement]
        
        self.revealValueCallback.onSuccess(response)
        wait(for: [self.expectation], timeout: 20.0)
        waitForUIUpdates()
        
        let allRecords = self.callback.data["records"] as! [[String: String]]
        let errors = allRecords.filter { $0["error"] != nil }
        let records = allRecords.filter { $0["error"] == nil }
        
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0]["token"], failureToken)
        XCTAssertEqual(errors[0]["error"], "Invalid Token")
        XCTAssertEqual(failureElement.actualValue, nil)
        XCTAssertEqual(failureElement.errorMessage.text, "Invalid Token")
        
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0]["token"], successToken)
        XCTAssertEqual(successElement.actualValue, "12345678")
        XCTAssertEqual(successElement.errorMessage.text, nil)
        XCTAssertEqual(successElement.skyflowLabelView.label.secureText!, "123-456-78")

    }
    func testRevealValueOnSuccessFormatCase3() { //format length is less than revealed data length
        let successToken = "123"
        let failureToken = "1234"
        let response = [
            "records": [["token": successToken, "value": "12345678"], ["token": failureToken, "error": "Invalid Token"]]
        ]
        
        let successElement = self.container.create(input: RevealElementInput(token: successToken, label: "name"), options: RevealElementOptions(format: "XXX-XXX", translation: ["X": "[0-9]"]))
        let failureElement = self.container.create(input: RevealElementInput(token: failureToken, label: "failed"))
        
        self.revealValueCallback.revealElements = [successElement, failureElement]
        
        self.revealValueCallback.onSuccess(response)
        wait(for: [self.expectation], timeout: 20.0)
        waitForUIUpdates()
        
        let allRecords = self.callback.data["records"] as! [[String: String]]
        let errors = allRecords.filter { $0["error"] != nil }
        let records = allRecords.filter { $0["error"] == nil }
        
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0]["token"], failureToken)
        XCTAssertEqual(errors[0]["error"], "Invalid Token")
        XCTAssertEqual(failureElement.actualValue, nil)
        XCTAssertEqual(failureElement.errorMessage.text, "Invalid Token")
        
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0]["token"], successToken)
        XCTAssertEqual(successElement.actualValue, "12345678")
        XCTAssertEqual(successElement.errorMessage.text, nil)
        XCTAssertEqual(successElement.skyflowLabelView.label.secureText!, "123-456")

    }
    
    func testRevealValueOnSuccessFormatCase4() { //format with some prefix
        let successToken = "123"
        let failureToken = "1234"
        let response = [
            "records": [["token": successToken, "value": "12345678"], ["token": failureToken, "error": "Invalid Token"]]
        ]
        
        let successElement = self.container.create(input: RevealElementInput(token: successToken, label: "name"), options: RevealElementOptions(format: "+91 XXX-XXX", translation: ["X": "[0-9]"]))
        let failureElement = self.container.create(input: RevealElementInput(token: failureToken, label: "failed"))
        
        self.revealValueCallback.revealElements = [successElement, failureElement]
        
        self.revealValueCallback.onSuccess(response)
        wait(for: [self.expectation], timeout: 20.0)
        waitForUIUpdates()
        
        let allRecords = self.callback.data["records"] as! [[String: String]]
        let errors = allRecords.filter { $0["error"] != nil }
        let records = allRecords.filter { $0["error"] == nil }
        
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0]["token"], failureToken)
        XCTAssertEqual(errors[0]["error"], "Invalid Token")
        XCTAssertEqual(failureElement.actualValue, nil)
        XCTAssertEqual(failureElement.errorMessage.text, "Invalid Token")
        
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0]["token"], successToken)
        XCTAssertEqual(successElement.actualValue, "12345678")
        XCTAssertEqual(successElement.errorMessage.text, nil)
        XCTAssertEqual(successElement.skyflowLabelView.label.secureText!, "+91 123-456")

    }
    func testRevealValueOnSuccessFormatCase5() { //translation and reveal data type is different
        let successToken = "123"
        let failureToken = "1234"
        let response = [
            "records": [["token": successToken, "value": "name"], ["token": failureToken, "error": "Invalid Token"]]
        ]
        
        let successElement = self.container.create(input: RevealElementInput(token: successToken, label: "name"), options: RevealElementOptions(format: "+91 XXX-XXX", translation: ["X": "[0-9]"]))
        let failureElement = self.container.create(input: RevealElementInput(token: failureToken, label: "failed"))
        
        self.revealValueCallback.revealElements = [successElement, failureElement]
        
        self.revealValueCallback.onSuccess(response)
        wait(for: [self.expectation], timeout: 20.0)
        waitForUIUpdates()
        
        let allRecords = self.callback.data["records"] as! [[String: String]]
        let errors = allRecords.filter { $0["error"] != nil }
        let records = allRecords.filter { $0["error"] == nil }
        
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0]["token"], failureToken)
        XCTAssertEqual(errors[0]["error"], "Invalid Token")
        XCTAssertEqual(failureElement.actualValue, nil)
        XCTAssertEqual(failureElement.errorMessage.text, "Invalid Token")
        
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0]["token"], successToken)
        XCTAssertEqual(successElement.actualValue, "name")
        XCTAssertEqual(successElement.errorMessage.text, nil)
        XCTAssertEqual(successElement.skyflowLabelView.label.secureText!, "+91 ") //not able to add another type of data

    }
    func testRevealValueOnSuccessFormatCase6() { // literal character if translation is not provided
        let successToken = "123"
        let failureToken = "1234"
        let response = [
            "records": [["token": successToken, "value": "name"], ["token": failureToken, "error": "Invalid Token"]]
        ]
        
        let successElement = self.container.create(input: RevealElementInput(token: successToken, label: "name"), options: RevealElementOptions(format: "+91 XXX-XXX", translation: ["Y": "[0-9]"]))
        let failureElement = self.container.create(input: RevealElementInput(token: failureToken, label: "failed"))
        
        self.revealValueCallback.revealElements = [successElement, failureElement]
        
        self.revealValueCallback.onSuccess(response)
        wait(for: [self.expectation], timeout: 20.0)
        waitForUIUpdates()
        
        let allRecords = self.callback.data["records"] as! [[String: String]]
        let errors = allRecords.filter { $0["error"] != nil }
        let records = allRecords.filter { $0["error"] == nil }
        
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0]["token"], failureToken)
        XCTAssertEqual(errors[0]["error"], "Invalid Token")
        XCTAssertEqual(failureElement.actualValue, nil)
        XCTAssertEqual(failureElement.errorMessage.text, "Invalid Token")
        
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0]["token"], successToken)
        XCTAssertEqual(successElement.actualValue, "name")
        XCTAssertEqual(successElement.errorMessage.text, nil)
        XCTAssertEqual(successElement.skyflowLabelView.label.secureText!, "+91 XXX-XXX") //not able to add another type of data

    }
    func testRevealInvalidBearerToken() {
        let expectation = XCTestExpectation()
        let callback = DemoAPICallback(expectation: expectation)
        
        self.client.vaultID = "id"
        self.client.vaultURL = "https://skyflow.com"
        let container = self.client.container(type: ContainerType.REVEAL)
        let input = RevealElementInput(token: "token", label: "test")
        let element = container?.create(input: input)
        
        UIWindow().addSubview(element!)
        
        container?.reveal(callback: callback.asRevealCallback)
        
        wait(for: [expectation], timeout: 20.0)
        // Invalid bearer token isn't scoped to any specific token, so RevealValueCallback routes it
        // through onFailure as a Skyflow.SkyflowError rather than folding it into the records array.
        XCTAssertTrue(callback.receivedResponse.contains("Token generated from 'getBearerToken' callback function is invalid"))
    }

    func testRevealValueOnFailureMixedTokenScopedAndUnscopedErrorsRoutesToOnFailure() {
        // Edge case: if a genuine network/API-level error (no "token") arrives in the same batch
        // as per-token errors, the whole thing is treated as a whole-request failure - the
        // per-token entries are discarded rather than partially surfaced via onSuccess. This
        // documents that behavior explicitly, since it's not obvious from reading either branch
        // in isolation.
        let scopedToken = "123"
        let networkError = NSError(domain: "NSURLErrorDomain", code: -1009, userInfo: [NSLocalizedDescriptionKey: "network down"])
        let response: [String: Any] = [
            "errors": [
                ["token": scopedToken, "error": "Invalid Token"],
                ["error": networkError]
            ]
        ]

        let element1 = self.container.create(input: RevealElementInput(token: scopedToken, label: "first"))
        self.revealValueCallback.revealElements = [element1]

        self.revealValueCallback.onFailure(response)
        wait(for: [self.expectation], timeout: 20.0)
        waitForUIUpdates()

        XCTAssertNil(self.callback.data["records"])
        XCTAssertEqual(self.callback.receivedResponse, "network down")
        XCTAssertEqual(element1.errorMessage.text, nil)
    }

    func testRevealRecordHttpCodeDefaultsToZeroWhenMissing() {
        let record = RevealRecord(["token": "abc"])
        XCTAssertEqual(record.httpCode, 0)
        XCTAssertNil(record.error)
    }

    func testRevealRecordErrorDiscriminatesSuccessFromFailure() {
        let success = RevealRecord(["token": "abc", "value": "1234", "httpCode": 200])
        let failure = RevealRecord(["token": "xyz", "error": "Tokens not found", "httpCode": 404])

        XCTAssertNil(success.error)
        XCTAssertEqual(failure.error, "Tokens not found")
        XCTAssertEqual(failure.httpCode, 404)
    }

    func testRevealResponseInitReturnsNilForMalformedBody() {
        XCTAssertNil(RevealResponse("not a dictionary"))
        XCTAssertNil(RevealResponse(["typo": []]))
        XCTAssertNil(RevealResponse(["records": "not an array"]))
    }

    // Verifies the real end-to-end wiring for a whole-request failure through
    // FlowVaultRevealAPICallback -> callRevealOnFailure -> LogCallback -> RevealCallback ->
    // SkyflowError.wrap, using a token provider that fails immediately (no network mocking
    // needed - TokenAPICallback's failure reaches the exact same callRevealOnFailure wrapping
    // as a real dispatch failure would). This is the plumbing that had a real bug (SkyflowError.wrap
    // losing the message entirely) until it was found and fixed earlier via a unit test on
    // SkyflowError.wrap directly - this test instead confirms the full real call chain, not just
    // the isolated function.
    func testDetokenizeTokenProviderFailureSurfacesAsSkyflowErrorThroughRealCallChain() {
        class FailingTokenProvider: TokenProvider {
            func getBearerToken(_ apiCallback: Callback) {
                apiCallback.onFailure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "TokenProvider error"]))
            }
        }
        let client = Client(Configuration(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: FailingTokenProvider()))
        let expectation = XCTestExpectation(description: "TokenProvider failure surfaces as SkyflowError")
        let callback = DemoAPICallback(expectation: expectation)

        client.detokenize(records: ["records": [["token": "tok1"]]], callback: callback.asRevealCallback)

        wait(for: [expectation], timeout: 10.0)

        XCTAssertEqual(callback.receivedResponse, "TokenProvider error")
    }

}
