/*
 * Copyright (c) 2022 Skyflow
*/

// swiftlint:disable file_length
import XCTest
@testable import Skyflow

// swiftlint:disable:next type_body_length
final class skyflow_iOS_revealUtilTests: XCTestCase {
    
    var revealApiCallback: RevealAPICallback! = nil
    var revealValueCallback: RevealValueCallback! = nil
    var expectation: XCTestExpectation! = nil
    var callback: DemoAPICallback! = nil
    
    var client: Client = Client(Configuration(tokenProvider: DemoTokenProvider()))
    var container: Container<RevealContainer>! = nil
    
    override func setUp() {
        self.expectation = XCTestExpectation()
        self.callback = DemoAPICallback(expectation: self.expectation)
        self.revealApiCallback = RevealAPICallback(callback: self.callback,
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
        self.revealApiCallback.onSuccess("token")
        
        wait(for: [self.expectation], timeout: 20.0)
        let errors = callback.data["errors"] as! [[String: NSError]]
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0]["error"], ErrorCodes.INVALID_URL().getErrorObject(contextOptions: ContextOptions()))
    }
    
    func testGetRequestSession() {
        self.revealApiCallback.connectionUrl = "https://www.example.org"
        
        let (request, session) = self.revealApiCallback.getRequestSession()
        XCTAssertEqual(request.url?.absoluteString, "https://www.example.org/detokenize")
        XCTAssertEqual(request.allHTTPHeaderFields!["Content-Type"], "application/json; utf-8")
        XCTAssertEqual(request.allHTTPHeaderFields!["Accept"], "application/json")
        XCTAssertEqual(request.allHTTPHeaderFields!["Authorization"], "Bearer ")
    }
    
    func testRevealRequestBody() {
        let record = RevealRequestRecord(token: "token")
        do {
            let result = try self.revealApiCallback.getRevealRequestBody(record: record)
            XCTAssertNotNil(result)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testProcessResponseError() {
        let revealedResponse = ["key": "value"]
        let serverError = NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "Internal Server Error"])
        do {
            let responseData = try JSONSerialization.data(withJSONObject: revealedResponse, options: .fragmentsAllowed)
            try self.revealApiCallback.processResponse(record: RevealRequestRecord(token: "token"), data: responseData, response: nil, error: serverError)
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
            let (success, failure) = try self.revealApiCallback.processResponse(record: RevealRequestRecord(token: "token"), data: responseData, response: httpResponse, error: nil)
            XCTAssertNil(success)
            XCTAssertNotNil(failure)
            XCTAssertEqual(failure?.error.localizedDescription, "Interface:  - Internal Server Error - request-id: RID")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testProcessResponseSuccess() {
        let revealedResponse = ["records": [["token": "token", "value": "value"]]]
        let httpResponse = HTTPURLResponse(url: URL(string: "https://www.example.org")!, statusCode: 200, httpVersion: "1.1", headerFields: ["x-request-id": "RID"])
        do {
            let responseData = try JSONSerialization.data(withJSONObject: revealedResponse, options: .fragmentsAllowed)
            let (success, failure) = try self.revealApiCallback.processResponse(record: RevealRequestRecord(token: "token"), data: responseData, response: httpResponse, error: nil)
            XCTAssertNil(failure)
            XCTAssertNotNil(success)
            XCTAssertEqual(success?.token_id, "token")
            XCTAssertEqual(success?.value, "value")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testHandleCallbacksSuccess() {
        let errorObject = NSError(domain: "", code: 200, userInfo: nil)
        let success = [RevealSuccessRecord(token_id: "token", value: "value")]
        
        self.revealApiCallback.handleCallbacks(success: success, failure: [], isSuccess: true, errorObject: nil)
        
        wait(for: [self.expectation], timeout: 20.0)
        let records = self.callback.data["records"] as! [[String: String]]
        
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0]["value"], "value")
        XCTAssertEqual(records[0]["token"], "token")
    }
    
    func testHandleCallbacksFailure() {
        let failure = RevealErrorRecord(id: "token", error: NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid Token"]))
        self.revealApiCallback.handleCallbacks(success: [], failure: [failure], isSuccess: true, errorObject: nil)
        
        wait(for: [self.expectation], timeout: 20.0)
        let errors = self.callback.data["errors"] as! [[String: Any]]
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0]["error"] as! NSError, failure.error)
        XCTAssertEqual(errors[0]["token"] as! String, "token")
    }
    
    func testHandleCallbacksError() {
        let error = NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid Token"])
        self.revealApiCallback.handleCallbacks(success: [], failure: [], isSuccess: false, errorObject: error)
        
        wait(for: [self.expectation], timeout: 20.0)
        let errors = self.callback.data["errors"] as! [[String: Any]]
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0]["error"] as! NSError, error)
    }
    
    func testGetTokensToErrors() {
        let errors = [["token": "1234"], ["token": "4321"]]
        
        let result = self.revealValueCallback.getTokensToErrors(errors)
        
        XCTAssertEqual(result["1234"], "Invalid Token")
        XCTAssertEqual(result["4321"], "Invalid Token")
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
                
        let errors = self.callback.data["errors"] as! [[String: String]]
        let records = self.callback.data["success"] as! [[String: String]]
        
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
            "records": [["token": successToken, "value": "John"]],
            "errors": [["token": failureToken, "error": "Invalid Token"]]
        ]
        
        let successElement = self.container.create(input: RevealElementInput(token: successToken, label: "name"), options: RevealElementOptions())
        let failureElement = self.container.create(input: RevealElementInput(token: failureToken, label: "failed"))
        
        self.revealValueCallback.revealElements = [successElement, failureElement]
        
        self.revealValueCallback.onSuccess(response)
        wait(for: [self.expectation], timeout: 20.0)
        waitForUIUpdates()
        
        let errors = self.callback.data["errors"] as! [[String: String]]
        let records = self.callback.data["success"] as! [[String: String]]
        
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
            "records": [["token": successToken, "value": "4567890"]],
            "errors": [["token": failureToken, "error": "Invalid Token"]]
        ]
        
        let successElement = self.container.create(input: RevealElementInput(token: successToken, label: "name"), options: RevealElementOptions(format: "XXX-XXX-X", translation: ["X": "[0-9]"]))
        let failureElement = self.container.create(input: RevealElementInput(token: failureToken, label: "failed"))
        
        self.revealValueCallback.revealElements = [successElement, failureElement]
        
        self.revealValueCallback.onSuccess(response)
        wait(for: [self.expectation], timeout: 20.0)
        waitForUIUpdates()
        
        let errors = self.callback.data["errors"] as! [[String: String]]
        let records = self.callback.data["success"] as! [[String: String]]
        
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
            "records": [["token": successToken, "value": "12345678"]],
            "errors": [["token": failureToken, "error": "Invalid Token"]]
        ]
        
        let successElement = self.container.create(input: RevealElementInput(token: successToken, label: "name"), options: RevealElementOptions(format: "XXX-XXX-XXX", translation: ["X": "[0-9]"]))
        let failureElement = self.container.create(input: RevealElementInput(token: failureToken, label: "failed"))
        
        self.revealValueCallback.revealElements = [successElement, failureElement]
        
        self.revealValueCallback.onSuccess(response)
        wait(for: [self.expectation], timeout: 20.0)
        waitForUIUpdates()
        
        let errors = self.callback.data["errors"] as! [[String: String]]
        let records = self.callback.data["success"] as! [[String: String]]
        
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
            "records": [["token": successToken, "value": "12345678"]],
            "errors": [["token": failureToken, "error": "Invalid Token"]]
        ]
        
        let successElement = self.container.create(input: RevealElementInput(token: successToken, label: "name"), options: RevealElementOptions(format: "XXX-XXX", translation: ["X": "[0-9]"]))
        let failureElement = self.container.create(input: RevealElementInput(token: failureToken, label: "failed"))
        
        self.revealValueCallback.revealElements = [successElement, failureElement]
        
        self.revealValueCallback.onSuccess(response)
        wait(for: [self.expectation], timeout: 20.0)
        waitForUIUpdates()
        
        let errors = self.callback.data["errors"] as! [[String: String]]
        let records = self.callback.data["success"] as! [[String: String]]
        
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
            "records": [["token": successToken, "value": "12345678"]],
            "errors": [["token": failureToken, "error": "Invalid Token"]]
        ]
        
        let successElement = self.container.create(input: RevealElementInput(token: successToken, label: "name"), options: RevealElementOptions(format: "+91 XXX-XXX", translation: ["X": "[0-9]"]))
        let failureElement = self.container.create(input: RevealElementInput(token: failureToken, label: "failed"))
        
        self.revealValueCallback.revealElements = [successElement, failureElement]
        
        self.revealValueCallback.onSuccess(response)
        wait(for: [self.expectation], timeout: 20.0)
        waitForUIUpdates()
        
        let errors = self.callback.data["errors"] as! [[String: String]]
        let records = self.callback.data["success"] as! [[String: String]]
        
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
            "records": [["token": successToken, "value": "name"]],
            "errors": [["token": failureToken, "error": "Invalid Token"]]
        ]
        
        let successElement = self.container.create(input: RevealElementInput(token: successToken, label: "name"), options: RevealElementOptions(format: "+91 XXX-XXX", translation: ["X": "[0-9]"]))
        let failureElement = self.container.create(input: RevealElementInput(token: failureToken, label: "failed"))
        
        self.revealValueCallback.revealElements = [successElement, failureElement]
        
        self.revealValueCallback.onSuccess(response)
        wait(for: [self.expectation], timeout: 20.0)
        waitForUIUpdates()
        
        let errors = self.callback.data["errors"] as! [[String: String]]
        let records = self.callback.data["success"] as! [[String: String]]
        
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
            "records": [["token": successToken, "value": "name"]],
            "errors": [["token": failureToken, "error": "Invalid Token"]]
        ]
        
        let successElement = self.container.create(input: RevealElementInput(token: successToken, label: "name"), options: RevealElementOptions(format: "+91 XXX-XXX", translation: ["Y": "[0-9]"]))
        let failureElement = self.container.create(input: RevealElementInput(token: failureToken, label: "failed"))
        
        self.revealValueCallback.revealElements = [successElement, failureElement]
        
        self.revealValueCallback.onSuccess(response)
        wait(for: [self.expectation], timeout: 20.0)
        waitForUIUpdates()
        
        let errors = self.callback.data["errors"] as! [[String: String]]
        let records = self.callback.data["success"] as! [[String: String]]
        
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
        
        container?.reveal(callback: callback)
        
        wait(for: [expectation], timeout: 20.0)
        print(callback.data)
        let errors = callback.data["errors"] as! [[String: NSError]]
        XCTAssertTrue(errors[0]["error"]!.localizedDescription.contains("Invalid Bearer token"))
    }
    
}
