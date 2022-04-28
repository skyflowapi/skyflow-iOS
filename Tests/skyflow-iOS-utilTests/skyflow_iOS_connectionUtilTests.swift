import XCTest
@testable import Skyflow


final class skyflow_iOS_connectionUtilTests: XCTestCase {
    
    var soapApiClient: SoapConnectionAPIClient! = nil
    var connectionApiClient: ConnectionAPIClient! = nil
    
    var detokenizeCallback: ConnectionDetokenizeCallback! = nil
    var client: Client! = nil
    
    override func setUp() {
        self.client = Client(Configuration(tokenProvider: DemoTokenProvider()))
        self.soapApiClient = SoapConnectionAPIClient(callback: DemoAPICallback(expectation: XCTestExpectation()),
                                                     skyflow: Client(Configuration(tokenProvider: DemoTokenProvider())),
                                                     contextOptions: ContextOptions())
        self.connectionApiClient = ConnectionAPIClient(callback: DemoAPICallback(expectation: XCTestExpectation()),
                                                       contextOptions: ContextOptions())
        
        self.detokenizeCallback = ConnectionDetokenizeCallback(
            skyflowClient: self.client,
            labelIDsToTokens: [:],
            apiClient: self.connectionApiClient,
            connectionType: .REST,
            config: ConnectionConfig(connectionURL: "", method: .POST),
            clientCallback: DemoAPICallback(expectation: XCTestExpectation()),
            contextOptions: ContextOptions())
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
    
    func testInvokeConnectionError() {
        let config = ConnectionConfig(connectionURL: "invalid url . com", method: .POST)
        do {
            try self.connectionApiClient.invokeConnection(token: "dummy_token", config: config)
            XCTFail("Not throwing on invalid url")
        } catch {
        }
    }
    
    func testConnectionCallbackHandler() {
        let expectation = XCTestExpectation(description: "success")
        let callback = DemoAPICallback(expectation: expectation)
        self.connectionApiClient.callback = callback
        let convertedResponse = ["message": "success"]
        
        self.connectionApiClient.handleCallbacks(isSuccess: true, convertedResponse: convertedResponse, stringResponse: nil, errors: [], errorObject: nil)
        wait(for: [expectation], timeout: 20.0)
        let result = callback.data
        XCTAssertEqual(result as! [String: String], convertedResponse)
    }
    
    func testConnectionCallbackHandlerOnPartialFailure() {
        let expectation = XCTestExpectation(description: "success")
        let callback = DemoAPICallback(expectation: expectation)
        self.connectionApiClient.callback = callback
        let convertedResponse = ["message": "error"]
        let errors = [ErrorCodes.EMPTY_CONNECTION_URL().getErrorObject(contextOptions: ContextOptions())]
        
        self.connectionApiClient.handleCallbacks(isSuccess: false, convertedResponse: convertedResponse, stringResponse: nil, errors: errors, errorObject: nil)
        wait(for: [expectation], timeout: 20.0)
        let result = callback.data
        XCTAssertEqual(result["success"] as! [String: String], convertedResponse)
        XCTAssertEqual(result["errors"] as! [NSError], errors)
    }
    
    func testConnectionCallbackHandlerOnFailure() {
        let expectation = XCTestExpectation(description: "success")
        let callback = DemoAPICallback(expectation: expectation)
        self.connectionApiClient.callback = callback
        let error = ErrorCodes.EMPTY_CONNECTION_URL().getErrorObject(contextOptions: ContextOptions())
        
        self.connectionApiClient.handleCallbacks(isSuccess: false, convertedResponse: nil, stringResponse: nil, errors: [], errorObject: error)
        wait(for: [expectation], timeout: 20.0)
        let result = callback.data
        XCTAssertEqual(result["errors"] as! [SkyflowError], [error])
    }
    
    func testDetokenizeCallbackMergeDicts() {
        let dict1 = ["id": "token"]
        let dict2 = ["token": "value"]
        
        let result = self.detokenizeCallback.mergeDicts(dict1, dict2)
        
        XCTAssertEqual(result["id"], "value")
    }
    
    func testConvertDetokenizeOp() {
        let detokenizeOutput = ["records": [["token": "given_token", "value": "value"]]]
        let result = self.detokenizeCallback.convertDetokenizeOutput(detokenizeOutput)
        
        XCTAssertEqual(result, ["given_token": "value"])
    }
    
    func testDetokenizeOnSuccessBadResponse() {
        let badResponse = ["key": "value"]
        let expectation = XCTestExpectation()
        let callback = DemoAPICallback(expectation: expectation)
        let tokenCallback = ConnectionTokenCallback(client: self.client, connectionType: .REST, config: [:], clientCallback: callback)
        
        self.detokenizeCallback.tokenCallback = tokenCallback
        self.detokenizeCallback.onSuccess(badResponse)
        
        wait(for: [expectation], timeout: 20.0)
        XCTAssertEqual(callback.receivedResponse, "Invalid Response from detokenize")
    }
    
    func testDetokenizeOnSuccessRest() {
        let response = ["records": [["token": "token", "value": "value"]]]
        let expectation = XCTestExpectation()
        let callback = DemoAPICallback(expectation: expectation)
        let tokenCallback = ConnectionTokenCallback(client: self.client!, connectionType: .REST, config: [:], clientCallback: callback)
        
        self.detokenizeCallback.tokenCallback = tokenCallback
        self.detokenizeCallback.onSuccess(response)
        
        wait(for: [expectation], timeout: 20.0)
        print(callback.receivedResponse)
        XCTAssertEqual(callback.receivedResponse, "Interface:  - Invalid Bearer token format")
        
    }
    
    func testDetokenizeOnSuccessSoap() {
        let response = ["records": [["token": "token", "value": "value"]]]
        let expectation = XCTestExpectation()
        let callback = DemoAPICallback(expectation: expectation)
        let tokenCallback = ConnectionTokenCallback(client: self.client!, connectionType: .SOAP, config: [:], clientCallback: callback)
        
        self.detokenizeCallback.tokenCallback = tokenCallback
        self.detokenizeCallback.connectionType = .SOAP
        self.detokenizeCallback.config = SoapConnectionConfig(connectionURL: "", requestXML: "")
        self.detokenizeCallback.onSuccess(response)
        
        wait(for: [expectation], timeout: 20.0)
        print(callback.receivedResponse)
        XCTAssertEqual(callback.receivedResponse, "Interface:  - Invalid Bearer token format")
    }
    
    func testRestInvalidToken() {
        let expectation = XCTestExpectation()
        let callback = DemoAPICallback(expectation: expectation)
        self.client.invokeConnection(config: ConnectionConfig(connectionURL: "www.http.org", method: .POST), callback: callback)
        
        wait(for: [expectation], timeout: 20.0)
        XCTAssertTrue(callback.receivedResponse.contains("Invalid Bearer token format"))
    }
    
    func testSoapInvalidToken() {
        let expectation = XCTestExpectation()
        let callback = DemoAPICallback(expectation: expectation)
        self.client.invokeSoapConnection(config: SoapConnectionConfig(connectionURL: "www.http.org", requestXML: "<xml>request</xml>"), callback: callback)
        
        wait(for: [expectation], timeout: 20.0)
        XCTAssertTrue(callback.receivedResponse.contains("Invalid Bearer token format"))
    }
    
}
