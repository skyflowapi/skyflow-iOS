import XCTest
@testable import Skyflow


final class skyflow_iOS_connectionUtilTests: XCTestCase {
    
    var soapApiClient: SoapConnectionAPIClient! = nil
    var connectionApiClient: ConnectionAPIClient! = nil
    
    override func setUp() {
        self.soapApiClient = SoapConnectionAPIClient(callback: DemoAPICallback(expectation: XCTestExpectation()), skyflow: Client(Configuration(tokenProvider: DemoTokenProvider())), contextOptions: ContextOptions())
        self.connectionApiClient = ConnectionAPIClient(callback: DemoAPICallback(expectation: XCTestExpectation()), contextOptions: ContextOptions())
    }
    
    func testSoapProcessResponse() {
        
        let apiResponse = "<xml>actual response</xml>"
        
        do {
            let data = apiResponse.data(using: .utf8)
            let response = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 200, httpVersion: "1.1", headerFields: ["Content-Type": "text/xml"])
            let result = try self.soapApiClient.processResponse(data: data, response: response, error: nil, responseXML: "")
            
            XCTAssertEqual(result, apiResponse)
        } catch {
            XCTFail(error.localizedDescription)
        }
        
    }
    
    func testConstructSoapRequestError() {
        let httpResponse = HTTPURLResponse(url: URL(string: "http://example.org")!, statusCode: 500, httpVersion: nil, headerFields: ["x-request-id": "RID"])!
        
        let serverError = "<error>Internal Server Error</error>"
        do {
            let data = try JSONSerialization.data(withJSONObject: serverError, options: .fragmentsAllowed)
            let errorObj = self.soapApiClient.constructApiError(data: data, httpResponse)!
            
            XCTAssertNotNil(errorObj.getXML(), serverError)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testConstructSoapRequest() {
        do {
            let result = try self.soapApiClient.constructRequest(url: URL(string: "https://example.org/")!, requestXML: "<xml>This is a request</xml>", headers: [:], token: "token")
            
            XCTAssertEqual(result.allHTTPHeaderFields!["X-Skyflow-Authorization"], "token")
            XCTAssertEqual(result.allHTTPHeaderFields!["Content-Type"], "text/xml; charset=utf-8")
            XCTAssertEqual(result.httpMethod, "POST")
            XCTAssertNotNil(result.httpBody)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testConnectionRequestSession() {
        let config = ConnectionConfig(connectionURL: "https://example.org", method: .POST)
        let token = "dummy_token"
        
        do {
            let (request, session) = try self.connectionApiClient.getRequestSession(config: config, token: token)
            
            XCTAssertEqual(request.allHTTPHeaderFields!["x-skyflow-authorization"], token)
            XCTAssertEqual(request.url?.absoluteString, config.connectionURL)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testConnectionProcessResponse() {
        let responseData = ["response": ["message": "success"]]
        do {
            let data = try JSONSerialization.data(withJSONObject: responseData, options: .fragmentsAllowed)
            let response = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 200, httpVersion: "1.1", headerFields: nil)
            let config = ConnectionConfig(connectionURL: "https://example.org", method: .POST)
            
            let (convertedResponse, errors, responseString) = try self.connectionApiClient.processResponse(data: data, response: response, error: nil, config: config)
            
            XCTAssertEqual(convertedResponse as! [String: [String: String]], responseData)
            XCTAssertNil(responseString)
            XCTAssertEqual(errors.count, 0)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testConnectionProcessResponseFailure() {
        let responseData = ["response": ["message": "success"]]
        do {
            let data = try JSONSerialization.data(withJSONObject: responseData, options: .fragmentsAllowed)
            let response = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 500, httpVersion: "1.1", headerFields: nil)
            let config = ConnectionConfig(connectionURL: "https://example.org", method: .POST)
            
            let _ = try self.connectionApiClient.processResponse(data: data, response: response, error: nil, config: config)
            XCTFail("Should have thrown on response code")
        } catch {
            if let skyflowErr = error as? SkyflowError {
                XCTAssertEqual(skyflowErr.code, 500)
            } else {
                XCTFail("Throwing unknown error")
            }
        }
    }
    
    func testConnectionProcessResponseError() {
        let responseData = ["response": ["message": "success"]]
        let netError = NSError(domain: "", code: 1039, userInfo: [NSLocalizedDescriptionKey: "Network Error"])
        do {
            let data = try JSONSerialization.data(withJSONObject: responseData, options: .fragmentsAllowed)
            let response = HTTPURLResponse(url: URL(string: "https://example.org")!, statusCode: 500, httpVersion: "1.1", headerFields: nil)
            let config = ConnectionConfig(connectionURL: "https://example.org", method: .POST)
            
            let _ = try self.connectionApiClient.processResponse(data: data, response: response, error: netError, config: config)
            XCTFail("Should have thrown on response code")
        } catch {
            XCTAssertEqual(error.localizedDescription, netError.localizedDescription)
        }
    }
}
