import XCTest
@testable import Skyflow


final class skyflow_iOS_collectUtilTests: XCTestCase {
    var collectCallback: CollectAPICallback! = nil
    var defaultRecord: [String: Any] = ["records": [["table": "table", "fields": ["field": "value"]]]]
    
    override func setUp() {
        self.collectCallback = CollectAPICallback(callback: DemoAPICallback(expectation: XCTestExpectation()), apiClient: APIClient(vaultID: "", vaultURL: "", tokenProvider: DemoTokenProvider()), records: defaultRecord, options: ICOptions(tokens: false, additionalFields: nil), contextOptions: ContextOptions())
    }
    
    func testBuildFieldsDict() {
        let dict = ["key": "value", "nested": ["key": "value"]] as [String: Any]
        let result = self.collectCallback.buildFieldsDict(dict: dict)
        XCTAssertEqual(dict["key"] as! String, result["key"] as! String)
        XCTAssertEqual(dict["nested"] as! [String: String], result["nested"] as! [String: String])
    }
    
    func testOnSuccessInvalidUrl() {
        let expectation = XCTestExpectation()
        let callback = DemoAPICallback(expectation: expectation)
        self.collectCallback.apiClient.vaultURL = "Invalid url"
        self.collectCallback.callback = callback
        
        self.collectCallback.onSuccess("string")
        wait(for: [expectation], timeout: 20.0)
        
        let result = callback.receivedResponse
        XCTAssert(result.contains("Bad or missing URL"))
    }
    
    func testGetRequestSession() {
        let url = URL(string: "https://example.org")!
        do {
            let (request, session) = try self.collectCallback.getRequestSession(url: url)
            
            XCTAssertEqual(request.allHTTPHeaderFields!["Authorization"], "Bearer ") // From DemoTokenProvider()
            let body = try JSONSerialization.jsonObject(with: request.httpBody!, options: .allowFragments) as! [String: Any]
            let records = body["records"] as! [[String: Any]]
            XCTAssertEqual(records.count, 2)
            XCTAssertEqual(records[0]["fields"] as! [String: String], ["field": "value"])
            XCTAssertEqual(records[0]["method"] as! String, "POST")
            XCTAssertEqual(records[0]["tableName"] as! String, "table")
            
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testGetCollectResponse() {
        let response = ["responses": [["records": [["skyflow_id": "SID"]]]]]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: response, options: .fragmentsAllowed)
            let result = try self.collectCallback.getCollectResponseBody(data: data)
            
            XCTAssertEqual(result as! [String: [[String: String]]], ["records": [
                [
                    "table": "table",
                    "skyflow_id": "SID"
                ]
            ]])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testGetCollectResponseWithTokens() {
        let response = ["responses": [["records": [["skyflow_id": "SID"]]], ["fields": ["field": "value"]]]]
        self.collectCallback.options = ICOptions()
        
        do {
            let data = try JSONSerialization.data(withJSONObject: response, options: .fragmentsAllowed)
            let result = try self.collectCallback.getCollectResponseBody(data: data)
            let records = result["records"] as! [[String: Any]]
            
            let expected = ["records": [["table": "table", "fields": ["field": "value", "skyflow_id": "SID"]]]]
            
            XCTAssertEqual(records.count, expected["records"]!.count)
            XCTAssertEqual(records[0]["table"] as! String, expected["records"]![0]["table"] as! String)
            XCTAssertEqual(records[0]["fields"] as! [String: String], expected["records"]![0]["fields"] as! [String: String])
            
            
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testProcessResponse() {
        let response = ["responses": [["records": [["skyflow_id": "SID"]]], ["fields": ["field": "value"]]]]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: response, options: .fragmentsAllowed)
            let response = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)
            
            let processedData = try self.collectCallback.processResponse(data: data, response: response, error: nil) as! [String: [[String: String]]]
            XCTAssertEqual(processedData, ["records": [["skyflow_id": "SID", "table": "table"]]])
            
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testProcessResponseError() {
        let response = ["responses": [["records": [["skyflow_id": "SID"]]], ["fields": ["field": "value"]]]]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: response, options: .fragmentsAllowed)
            let response = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)
            
            let processedData = try self.collectCallback.processResponse(data: data, response: response, error: NSError(domain: "", code: 400, userInfo: nil)) as! [String: [[String: String]]]
            XCTFail("Should have thrown error")
            
        } catch {
        }
    }
    
    func testProcessResponseFailure() {
        let response = ["error": ["message": "Internal Server Error"]]
        do {
            let data = try JSONSerialization.data(withJSONObject: response, options: .fragmentsAllowed)
            let response = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 500, httpVersion: "1.1", headerFields: ["x-request-id": "RID"])
            
            try self.collectCallback.processResponse(data: data, response: response, error: nil)
            XCTFail("Not throwing on Api Error")
            
        } catch {
            XCTAssertEqual(error.localizedDescription, "Interface:  - Internal Server Error - request-id: RID")
        }
    }

}
