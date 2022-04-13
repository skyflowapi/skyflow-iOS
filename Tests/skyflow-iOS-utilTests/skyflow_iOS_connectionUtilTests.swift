import XCTest
@testable import Skyflow


final class skyflow_iOS_connectionUtilTests: XCTestCase {
    
    var soapApiClient: SoapConnectionAPIClient! = nil
    
    override func setUp() {
        self.soapApiClient = SoapConnectionAPIClient(callback: DemoAPICallback(expectation: XCTestExpectation()), skyflow: Client(Configuration(tokenProvider: DemoTokenProvider())), contextOptions: ContextOptions())
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
        let record = GetByIdRecord(ids: ["one", "two"], table: "table", redaction: "REDACTED")
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
}
