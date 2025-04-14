/*
 * Copyright (c) 2022 Skyflow
*/

// swiftlint:disable file_length
import XCTest
@testable import Skyflow

// swiftlint:disable:next type_body_length
final class skyflow_iOS_getByIdUtilTests: XCTestCase {
    
    var revealApiCallback: RevealByIDAPICallback! = nil
    
    override func setUp() {
        self.revealApiCallback = RevealByIDAPICallback(callback: DemoAPICallback(expectation: XCTestExpectation()),
                                                       apiClient: APIClient(vaultID: "", vaultURL: "", tokenProvider: DemoTokenProvider()),
                                                       connectionUrl: "",
                                                       records: [],
                                                       contextOptions: ContextOptions())
    }
    
    func testBuildFields() {
        let input = ["key": "value", "nested": ["key": "value"]] as [String: Any]
        
        let output = self.revealApiCallback.buildFieldsDict(dict: input)
        
        XCTAssertEqual(input["key"] as! String, output["key"] as! String)
        XCTAssertEqual(input["nested"] as! [String: String], output["nested"] as! [String: String])
    }
    
    func testApiCallbackInvalidUrl() {
        let expectation = XCTestExpectation(description: "expect invalid url failure")
        let failureCallback = DemoAPICallback(expectation: expectation)
        let record = GetByIdRecord(ids: ["one", "two"], table: "table", redaction: "REDACTED")
        self.revealApiCallback.records = [record]
        self.revealApiCallback.connectionUrl = "invalid url"
        self.revealApiCallback.apiClient.vaultURL = "dummy"
        self.revealApiCallback.callback = failureCallback
        self.revealApiCallback.onSuccess("dummy_token")
        
        wait(for: [expectation], timeout: 30.0)
        let result = failureCallback.data["errors"] as! [[String: NSError]]
        XCTAssertEqual(result[0]["error"]?.localizedDescription, "unsupported URL")
    }
    
    func testGetRequestSession() {
        let urlComponents = URLComponents(string: "https://example.org")
        let (request, _) = self.revealApiCallback.getRequestSession(urlComponents: urlComponents)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.allHTTPHeaderFields!["Content-Type"], "application/json; utf-8")
        XCTAssertEqual(request.allHTTPHeaderFields!["Accept"], "application/json")
    }
    
    func testGetUrlComponents() {
        let record = GetByIdRecord(ids: ["one", "two"], table: "table", redaction: "REDACTED")
        self.revealApiCallback.connectionUrl = "https://example.org"
        let urlComponents = self.revealApiCallback.getUrlComponents(record: record)!
        
        XCTAssertEqual(urlComponents.queryItems?.count, 3)
        XCTAssertEqual(urlComponents.queryItems![0], URLQueryItem(name: "skyflow_ids", value: "one"))
        XCTAssertEqual(urlComponents.queryItems![1], URLQueryItem(name: "skyflow_ids", value: "two"))
        XCTAssertEqual(urlComponents.queryItems![2], URLQueryItem(name: "redaction", value: record.redaction))
        XCTAssertEqual(urlComponents.url?.path, "/table")
    }
    
    func testConstructError() {
        let record = GetByIdRecord(ids: ["one", "two"], table: "table", redaction: "REDACTED")
        let httpResponse = HTTPURLResponse(url: URL(string: "http://example.org")!, statusCode: 500, httpVersion: nil, headerFields: ["x-request-id": "RID"])!
        
        let serverError = ["error": ["message": "Internal Server Error"]]
        do {
            let data = try JSONSerialization.data(withJSONObject: serverError, options: .fragmentsAllowed)
            let errorObj = try self.revealApiCallback.constructApiError(record: record, data, httpResponse)
            
            XCTAssertNotNil(errorObj["error"])
            XCTAssertEqual(errorObj["error"] as! NSError,
                           ErrorCodes.APIError(code: httpResponse.statusCode, message: "Internal Server Error - request-id: RID").getErrorObject(contextOptions: ContextOptions()))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testProcessResponse() {
        let record = GetByIdRecord(ids: ["one", "two"], table: "table", redaction: "REDACTED")
        let apiResponse = ["records":[["table": "table", "skyflow_id": "SID"]]] as [String: Any]
        do {
            let data = try JSONSerialization.data(withJSONObject: apiResponse, options: .fragmentsAllowed)
            let processedRespoonse = try self.revealApiCallback.processResponse(record: record, data)
            
            print(processedRespoonse)
            XCTAssertEqual(processedRespoonse.count, 1)
            XCTAssertEqual(processedRespoonse[0]["table"] as! String, "table")
            XCTAssertEqual(processedRespoonse[0]["id"] as! String, "SID")
            XCTAssertEqual(processedRespoonse[0]["id"] as! String, "SID")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testConstructRevealRecords() {
        let records = [["table": "table", "id": "SID"]]
        let errors = [["error": ErrorCodes.APIError(code: 500, message: "description").getErrorObject(contextOptions: ContextOptions())]] 
        
        let revealRecord = self.revealApiCallback.constructRevealRecords(records, errors)
        XCTAssertEqual(records, revealRecord["records"] as! [[String: String]])
        XCTAssertEqual(errors[0]["error"], (revealRecord["errors"] as! [[String: NSError]])[0]["error"])
    }
    
    func testProcessUrlResponseFailure() {
        let record = GetByIdRecord(ids: ["one", "two"], table: "table", redaction: "REDACTED")
        let netError = NSError(domain: "", code: 1039, userInfo: [NSLocalizedDescriptionKey: "Network Error"])

        do {
            
            let _ = try self.revealApiCallback.processURLResponse(record: record, data: nil, response: nil, error: netError)
            
            XCTFail("Not throwing on failure")
        } catch {
            XCTAssertEqual(error as NSError, netError)
        }

    }
    
    func testProcessUrlResponseNoData() {
        let record = GetByIdRecord(ids: ["one", "two"], table: "table", redaction: "REDACTED")

        do {
            let response = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)
            
            let (responseArray, errorResponse) = try self.revealApiCallback.processURLResponse(record: record, data: nil, response: response, error: nil)
            
            XCTAssertNil(responseArray)
            XCTAssertNil(errorResponse)
        } catch {
            XCTFail(error.localizedDescription)
        }

    }
    
    func testProcessUrlResponseError() {
        let responseData = ["error": ["message": "Internal server error"]]
        let record = GetByIdRecord(ids: ["one", "two"], table: "table", redaction: "REDACTED")

        do {
            let data = try JSONSerialization.data(withJSONObject: responseData, options: .fragmentsAllowed)
            let response = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 500, httpVersion: "1.1", headerFields: nil)
            
            let (responseArray, errorObj) = try self.revealApiCallback.processURLResponse(record: record, data: data, response: response, error: nil)
            
            XCTAssertNil(responseArray)
            
            XCTAssertNotNil(errorObj!["error"])
            XCTAssertEqual(errorObj!["error"] as! NSError,
                           ErrorCodes.APIError(code: response!.statusCode, message: "Internal server error").getErrorObject(contextOptions: ContextOptions()))
        } catch {
            XCTFail(error.localizedDescription)
        }

    }
    
    func testProcessUrlResponseSuccess() {
        let responseData = ["records":[["table": "table", "skyflow_id": "SID"]]] as [String: Any]
        let record = GetByIdRecord(ids: ["one", "two"], table: "table", redaction: "REDACTED")

        do {
            let data = try JSONSerialization.data(withJSONObject: responseData, options: .fragmentsAllowed)
            let response = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)
            
            let (responseArray, errorObj) = try self.revealApiCallback.processURLResponse(record: record, data: data, response: response, error: nil)
            
            XCTAssertNil(errorObj)
            XCTAssertNotNil(responseArray)
            
            let processedRespoonse = responseArray!
            
            print(processedRespoonse)
            XCTAssertEqual(processedRespoonse.count, 1)
            XCTAssertEqual(processedRespoonse[0]["table"] as! String, "table")
            XCTAssertEqual(processedRespoonse[0]["id"] as! String, "SID")
            XCTAssertEqual(processedRespoonse[0]["id"] as! String, "SID")
        } catch {
            XCTFail(error.localizedDescription)
        }

    }
    
    func testHandleCallbacksFailure() {
        let expectation = XCTestExpectation()
        let callback = DemoAPICallback(expectation: expectation)
        self.revealApiCallback.callback = callback
        
        let errorObject = NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Not found"])
        self.revealApiCallback.handleCallbacks(outputArray: [[:]], errorArray: [[:]], isSuccess: false, errorObject: errorObject)
        
        wait(for: [expectation], timeout: 20.0)
        let errors = callback.data["errors"] as! [[String: NSError]]
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0]["error"], errorObject)
        
    }
    
    func testHandleCallbacksError() {
        let expectation = XCTestExpectation()
        let callback = DemoAPICallback(expectation: expectation)
        self.revealApiCallback.callback = callback
        
        let errorObject = NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "Internal Server Error"])
        let errors = [["error": errorObject]]
        let output = [["skyflow_id": "SID", "value": "val"]]
        self.revealApiCallback.handleCallbacks(outputArray: output, errorArray: errors, isSuccess: true, errorObject: nil)
        
        wait(for: [expectation], timeout: 20.0)
        let outputError = callback.data["errors"] as! [[String: NSError]]
        let records = callback.data["records"] as! [[String: String]]
        XCTAssertEqual(outputError.count, 1)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0], output[0])
        XCTAssertEqual(outputError[0], errors[0])
        
    }
    
    func testHandleCallbacksSuccess() {
        let expectation = XCTestExpectation()
        let callback = DemoAPICallback(expectation: expectation)
        self.revealApiCallback.callback = callback
        
        let output = [["skyflow_id": "SID", "value": "val"]]
        self.revealApiCallback.handleCallbacks(outputArray: output, errorArray: [], isSuccess: true, errorObject: nil)
        
        wait(for: [expectation], timeout: 20.0)
        let records = callback.data["records"] as! [[String: String]]
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0], output[0])
    }


}
