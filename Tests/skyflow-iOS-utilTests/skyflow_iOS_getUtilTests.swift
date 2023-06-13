//
//  skyflow_iOS_getUtilTests.swift
//  
//
//  Created by Bharti Sagar on 14/06/23.
//

import XCTest
@testable import Skyflow

final class skyflow_iOS_getUtilTests: XCTestCase {

    
    var getApiCallback: GetAPICallback! = nil
    
    override func setUp() {
        self.getApiCallback = GetAPICallback(callback: DemoAPICallback(expectation: XCTestExpectation()),
                                                       apiClient: APIClient(vaultID: "", vaultURL: "", tokenProvider: DemoTokenProvider()),
                                                       connectionUrl: "",
                                             records: [], getOptions: GetOptions(),
                                                       contextOptions: ContextOptions())
    }
    
    func testBuildFields() {
        let input = ["key": "value", "nested": ["key": "value"]] as [String: Any]
        
        let output = self.getApiCallback.buildFieldsDict(dict: input)
        
        XCTAssertEqual(input["key"] as! String, output["key"] as! String)
        XCTAssertEqual(input["nested"] as! [String: String], output["nested"] as! [String: String])
    }
    func testBuildFieldsDictShouldReturnCorrectResult() {
        // Arrange
        let inputDict: [String: Any] = [
            "key1": "value1",
            "key2": [
                "key3": "value3",
                "key4": "value4"
            ]
        ]
        
        // Act
        let result = self.getApiCallback.buildFieldsDict(dict: inputDict)
        
        // Assert
        XCTAssertEqual(result["key1"] as? String, "value1")
        XCTAssertEqual((result["key2"] as? [String: Any])?["key3"] as? String, "value3")
        XCTAssertEqual((result["key2"] as? [String: Any])?["key4"] as? String, "value4")
    }
    func testBuildFieldsDictWithNonSerializableValueShouldReturnOriginalDictionary() {
        // Arrange
        let inputDict: [String: Any] = [
            "key1": "value1",
            "key2": GetOptions()
        ]
        
        // Act
        let result =  self.getApiCallback.buildFieldsDict(dict: inputDict)
        
        // Assert
        XCTAssertTrue(result.keys.contains("key1"))
        XCTAssertTrue(result.keys.contains("key2"))

    }
    func testBuildFieldsDictWithEmptyDictionaryShouldReturnEmptyDictionary() {
        // Arrange
        let inputDict: [String: Any] = [:]

        let result = self.getApiCallback.buildFieldsDict(dict: inputDict)
        
        XCTAssertTrue(result.isEmpty)
    }
    
    func testApiCallbackInvalidUrl() {
        let expectation = XCTestExpectation(description: "expect invalid url failure")
        let failureCallback = DemoAPICallback(expectation: expectation)
        
        self.getApiCallback.connectionUrl = "invalid url"
        self.getApiCallback.callback = failureCallback
        self.getApiCallback.onSuccess("dummy_token")
        
        wait(for: [expectation], timeout: 30.0)
        let result = failureCallback.data["errors"] as! [[String: NSError]]
        XCTAssertEqual(result[0]["error"], ErrorCodes.INVALID_URL().getErrorObject(contextOptions: ContextOptions()))
    }
    
    func testGetRequestSession() {
        let urlComponents = URLComponents(string: "https://example.org")
        let (request, _) = self.getApiCallback.getRequestSession(urlComponents: urlComponents)
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.allHTTPHeaderFields!["Content-Type"], "application/json; utf-8")
        XCTAssertEqual(request.allHTTPHeaderFields!["Accept"], "application/json")
    }
    
    func testGetUrlComponentsIdRecord() {
        let record = GetRecord(ids: ["one", "two"], table: "table", redaction: "REDACTED")
        self.getApiCallback.connectionUrl = "https://example.org"
        let urlComponents = self.getApiCallback.getUrlComponents(record: record, getOptions: GetOptions())!
        
        XCTAssertEqual(urlComponents.queryItems?.count, 3)
        XCTAssertEqual(urlComponents.queryItems![0], URLQueryItem(name: "skyflow_ids", value: "one"))
        XCTAssertEqual(urlComponents.queryItems![1], URLQueryItem(name: "skyflow_ids", value: "two"))
        XCTAssertEqual(urlComponents.queryItems![2], URLQueryItem(name: "redaction", value: record.redaction))
        XCTAssertEqual(urlComponents.url?.path, "/table")
    }
    func testGetUrlComponentsIdRecordWithToken() {
        let record = GetRecord(ids: ["one", "two"], table: "table")
        self.getApiCallback.connectionUrl = "https://example.org"
        let urlComponents = self.getApiCallback.getUrlComponents(record: record, getOptions: GetOptions(tokens: true))!
        
        XCTAssertEqual(urlComponents.queryItems?.count, 3)
        XCTAssertEqual(urlComponents.queryItems![0], URLQueryItem(name: "skyflow_ids", value: "one"))
        XCTAssertEqual(urlComponents.queryItems![1], URLQueryItem(name: "skyflow_ids", value: "two"))
        XCTAssertEqual(urlComponents.queryItems![2], URLQueryItem(name: "tokenization", value: String(true)))
        XCTAssertEqual(urlComponents.url?.path, "/table")
    }
    func testGetUrlComponents() {
        let record = GetRecord(ids: ["123", "456"], table: "users", redaction: RedactionType.PLAIN_TEXT.rawValue)
        self.getApiCallback.connectionUrl = "https://example.org"
        let getOptions = GetOptions(tokens: false)
        
        let urlComponents = self.getApiCallback.getUrlComponents(record: record, getOptions: getOptions)
        XCTAssertEqual(urlComponents?.string, "https://example.org/users?skyflow_ids=123&skyflow_ids=456&redaction=PLAIN_TEXT")
    }
    func testGetUrlComponentsTokenTrue() {
        let record = GetRecord(ids: ["123", "456"], table: "users")
        self.getApiCallback.connectionUrl = "https://example.org"
        let getOptions = GetOptions(tokens: true)
        
        let urlComponents = self.getApiCallback.getUrlComponents(record: record, getOptions: getOptions)
        XCTAssertEqual(urlComponents?.string, "https://example.org/users?skyflow_ids=123&skyflow_ids=456&tokenization=true")
    }
    func testGetUrlComponentsColumnRecord() {
        let record = GetRecord(columnValues: ["1","2"], table: "table", columnName: "col", redaction: RedactionType.PLAIN_TEXT.rawValue)
        self.getApiCallback.connectionUrl = "https://example.org"
        let urlComponents = self.getApiCallback.getUrlComponents(record: record, getOptions: GetOptions(tokens: false))!
        
        XCTAssertEqual(urlComponents.queryItems?.count, 4)
        XCTAssertEqual(urlComponents.queryItems![0], URLQueryItem(name: "columnName", value: "col"))
        XCTAssertEqual(urlComponents.queryItems![1], URLQueryItem(name: "columnValues", value: "1"))
        XCTAssertEqual(urlComponents.queryItems![2], URLQueryItem(name: "columnValues", value: "2"))
        XCTAssertEqual(urlComponents.queryItems![3], URLQueryItem(name: "redaction", value: RedactionType.PLAIN_TEXT.rawValue))
        XCTAssertEqual(urlComponents.url?.path, "/table")
    }
    func testConstructError() {
        let record = GetRecord(ids: ["one", "two"], table: "table", redaction: "REDACTED")
        let httpResponse = HTTPURLResponse(url: URL(string: "http://example.org")!, statusCode: 500, httpVersion: nil, headerFields: ["x-request-id": "RID"])!
        
        let serverError = ["error": ["message": "Internal Server Error"]]
        do {
            let data = try JSONSerialization.data(withJSONObject: serverError, options: .fragmentsAllowed)
            let errorObj = try self.getApiCallback.constructApiError(record: record, data, httpResponse)
            
            XCTAssertNotNil(errorObj["error"])
            XCTAssertEqual(errorObj["error"] as! NSError,
                           ErrorCodes.APIError(code: httpResponse.statusCode, message: "Internal Server Error - request-id: RID").getErrorObject(contextOptions: ContextOptions()))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    func testConstructError2() {
        let record = GetRecord(columnValues: ["one", "two"], table: "table", columnName: "columnName", redaction: "REDACTED")
        let httpResponse = HTTPURLResponse(url: URL(string: "http://example.org")!, statusCode: 500, httpVersion: nil, headerFields: ["x-request-id": "RID"])!
        
        let serverError = ["error": ["message": "Internal Server Error"]]
        do {
            let data = try JSONSerialization.data(withJSONObject: serverError, options: .fragmentsAllowed)
            let errorObj = try self.getApiCallback.constructApiError(record: record, data, httpResponse)
            
            XCTAssertNotNil(errorObj["error"])
            XCTAssertEqual(errorObj["error"] as! NSError,
                           ErrorCodes.APIError(code: httpResponse.statusCode, message: "Internal Server Error - request-id: RID").getErrorObject(contextOptions: ContextOptions()))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    func testConstructApiErrorWithIds() {
        let record = GetRecord(ids: ["1", "2", "3"], table: "table")
        let safeData = try! JSONSerialization.data(withJSONObject: ["error": ["message": "Error message"]], options: [])
        let httpResponse = HTTPURLResponse(url: URL(string: "http://example.com")!, statusCode: 404, httpVersion: nil, headerFields: nil)!
        
        do {
            let result = try self.getApiCallback.constructApiError(record: record, safeData, httpResponse)
            
            XCTAssertEqual(result["ids"] as? [String], ["1", "2", "3"])
            XCTAssertNil(result["columnValues"])
            XCTAssertNil(result["columnName"])
            XCTAssertNotNil(result["error"])
            
            let error = result["error"] as! NSError
            XCTAssertEqual(error.code, 404)
            XCTAssertEqual(error.localizedDescription, "Interface:  - Error message")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    func testConstructApiErrorWithColumnValues() {
        let record = GetRecord(columnValues: ["value1", "value2"], table: "table", columnName: "column", redaction: RedactionType.PLAIN_TEXT.rawValue)
        let safeData = try! JSONSerialization.data(withJSONObject: ["error": ["message": "Error message"]], options: [])
        let httpResponse = HTTPURLResponse(url: URL(string: "http://example.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)!
        
        do {
            let result = try self.getApiCallback.constructApiError(record: record, safeData, httpResponse)
            
            XCTAssertNil(result["ids"])
            XCTAssertEqual(result["columnValues"] as? [String], ["value1", "value2"])
            XCTAssertEqual(result["columnName"] as? String, "column")
            XCTAssertNotNil(result["error"])
            
            let error = result["error"] as! NSError
            XCTAssertEqual(error.code, 500)
            XCTAssertEqual(error.localizedDescription, "Interface:  - Error message")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }


    
    func testProcessResponse() {
        let record = GetRecord(ids: ["one", "two"], table: "table", redaction: "REDACTED")
        let apiResponse = ["records":[["table": "table", "skyflow_id": "SID"]]] as [String: Any]
        do {
            let data = try JSONSerialization.data(withJSONObject: apiResponse, options: .fragmentsAllowed)
            let processedRespoonse = try self.getApiCallback.processResponse(record: record, data)
            
            print(processedRespoonse)
            XCTAssertEqual(processedRespoonse.count, 1)
            XCTAssertEqual(processedRespoonse[0]["table"] as! String, "table")
            XCTAssertEqual(processedRespoonse[0]["id"] as! String, "SID")
            XCTAssertEqual(processedRespoonse[0]["id"] as! String, "SID")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testconstructGetRecords() {
        let records = [["table": "table", "id": "SID"]]
        let errors = [["error": ErrorCodes.APIError(code: 500, message: "description").getErrorObject(contextOptions: ContextOptions())]]
        
        let getRecord = self.getApiCallback.constructGetRecords(records, errors)
        XCTAssertEqual(records, getRecord["records"] as! [[String: String]])
        XCTAssertEqual(errors[0]["error"], (getRecord["errors"] as! [[String: NSError]])[0]["error"])
    }
    
    func testProcessUrlResponseFailure() {
        let record = GetRecord(ids: ["one", "two"], table: "table", redaction: "REDACTED")
        let netError = NSError(domain: "", code: 1039, userInfo: [NSLocalizedDescriptionKey: "Network Error"])

        do {
            
            let _ = try self.getApiCallback.processURLResponse(record: record, data: nil, response: nil, error: netError)
            
            XCTFail("Not throwing on failure")
        } catch {
            XCTAssertEqual(error as NSError, netError)
        }

    }
    
    func testProcessUrlResponseNoData() {
        let record = GetRecord(ids: ["one", "two"], table: "table", redaction: "REDACTED")

        do {
            let response = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)
            
            let (responseArray, errorResponse) = try self.getApiCallback.processURLResponse(record: record, data: nil, response: response, error: nil)
            
            XCTAssertNil(responseArray)
            XCTAssertNil(errorResponse)
        } catch {
            XCTFail(error.localizedDescription)
        }

    }
    
    func testProcessUrlResponseError() {
        let responseData = ["error": ["message": "Internal server error"]]
        let record = GetRecord(ids: ["one", "two"], table: "table", redaction: "REDACTED")

        do {
            let data = try JSONSerialization.data(withJSONObject: responseData, options: .fragmentsAllowed)
            let response = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 500, httpVersion: "1.1", headerFields: nil)
            
            let (responseArray, errorObj) = try self.getApiCallback.processURLResponse(record: record, data: data, response: response, error: nil)
            
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
        let record = GetRecord(ids: ["one", "two"], table: "table", redaction: "REDACTED")

        do {
            let data = try JSONSerialization.data(withJSONObject: responseData, options: .fragmentsAllowed)
            let response = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)
            
            let (responseArray, errorObj) = try self.getApiCallback.processURLResponse(record: record, data: data, response: response, error: nil)
            
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
        self.getApiCallback.callback = callback
        
        let errorObject = NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "Not found"])
        self.getApiCallback.handleCallbacks(outputArray: [[:]], errorArray: [[:]], isSuccess: false, errorObject: errorObject)
        
        wait(for: [expectation], timeout: 20.0)
        let errors = callback.data["errors"] as! [[String: NSError]]
        XCTAssertEqual(errors.count, 1)
        XCTAssertEqual(errors[0]["error"], errorObject)
        
    }
    
    func testHandleCallbacksError() {
        let expectation = XCTestExpectation()
        let callback = DemoAPICallback(expectation: expectation)
        self.getApiCallback.callback = callback
        
        let errorObject = NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "Internal Server Error"])
        let errors = [["error": errorObject]]
        let output = [["skyflow_id": "SID", "value": "val"]]
        self.getApiCallback.handleCallbacks(outputArray: output, errorArray: errors, isSuccess: true, errorObject: nil)
        
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
        self.getApiCallback.callback = callback
        
        let output = [["skyflow_id": "SID", "value": "val"]]
        self.getApiCallback.handleCallbacks(outputArray: output, errorArray: [], isSuccess: true, errorObject: nil)
        
        wait(for: [expectation], timeout: 20.0)
        let records = callback.data["records"] as! [[String: String]]
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records[0], output[0])
    }


}
