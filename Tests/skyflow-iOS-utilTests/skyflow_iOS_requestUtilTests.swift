/*
 * Copyright (c) 2022 Skyflow
*/

// swiftlint:disable file_length
import XCTest
@testable import Skyflow

// swiftlint:disable:next type_body_length
final class skyflow_iOS_requestUtilTests: XCTestCase {
    func testGetLowercaseHeaders() {
        let headers = ["Content-Type": "application/json", "X-Skyflow-Authorization": "Token"]
        let expectedResult = ["content-type": "application/json", "x-skyflow-authorization": "Token"]
        
        XCTAssertEqual(RequestHelpers.getLowerCasedHeaders(headers: headers), expectedResult)
    }
    
    func testGetRequestByContentTypeJson() {
        var request = URLRequest(url: URL(string: "http://example.org")!)
        request.addValue("application/json", forHTTPHeaderField: "Content-type")
        
        let body = ["key": "value"]
        
        do {
            let result = try RequestHelpers.getRequestByContentType(request, body)
            let resultBody = try JSONSerialization.jsonObject(with: result.httpBody!, options: .allowFragments)
            XCTAssertEqual(resultBody as! [String : String], body)
        } catch {
            XCTFail("Unexpected error:" + error.localizedDescription)
        }
    }
    
    func testGetRequestByContentTypeFormUrlencoded() {
        var request = URLRequest(url: URL(string: "http://example.org")!)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-type")
        
        let body = ["key": "value"]
        let expected = "key=value"
        
        do {
            let result = try RequestHelpers.getRequestByContentType(request, body)
            let resultBody = String(data: result.httpBody!, encoding: .utf8)
            XCTAssertEqual(resultBody, expected)
        } catch {
            XCTFail("Unexpected error:" + error.localizedDescription)
        }
    }
    
    func testGetRequestByContentTypeFormData() {
        var request = URLRequest(url: URL(string: "http://example.org")!)
        request.addValue("multipart/form-data", forHTTPHeaderField: "Content-type")
        
        let body = ["key": "value", "nested": ["key": "value"]] as [String: Any]
        do {
            let result = try RequestHelpers.getRequestByContentType(request, body)
            let resultBody = String(data: result.httpBody!, encoding: .utf8)
            XCTAssert(((resultBody?.contains("\r\nContent-Disposition: form-data; name=\"key\"\r\n\r\nvalue\r\n")) != nil))
            
            XCTAssert(((resultBody?.contains("\r\nContent-Disposition: form-data; name=\"nested[key]\"\r\n\r\nvalue\r\n")) != nil))
        } catch {
            XCTFail("Unexpected error:" + error.localizedDescription)
        }
    }
    
    func testCreateRequest() {
        let url = URL(string: "http://example.org")!
        let body = ["key": "value"]
        let headers = ["x-skyflow-auth": "token"]
        
        do {
            let result = try RequestHelpers.createRequest(url: url, method: .POST, body: body, headers: headers, contextOptions: ContextOptions())
            let resultBody = try JSONSerialization.jsonObject(with: result.httpBody!, options: .allowFragments)
            
            XCTAssertEqual(result.url?.absoluteString, url.absoluteString)
            XCTAssertEqual(resultBody as! [String : String], body)
            XCTAssertNotNil(result.allHTTPHeaderFields)
            XCTAssertEqual(result.allHTTPHeaderFields!["x-skyflow-auth"], "token")
            XCTAssertEqual(result.allHTTPHeaderFields!["Content-Type"], "application/json")
        } catch {
            XCTFail("Unexpected error:" + error.localizedDescription)
        }
    }
    
    func testCreateRequestOverrideContentType() {
        let url = URL(string: "http://example.org")!
        let body = ["key": "value"]
        let headers = ["CoNtEnt-TypE": "user-content-type"]
        
        do {
            let result = try RequestHelpers.createRequest(url: url, method: .POST, body: body, headers: headers, contextOptions: ContextOptions())
            let resultBody = try JSONSerialization.jsonObject(with: result.httpBody!, options: .allowFragments)
            
            XCTAssertEqual(result.url?.absoluteString, url.absoluteString)
            XCTAssertEqual(resultBody as! [String : String], body)
            XCTAssertNotNil(result.allHTTPHeaderFields)
            XCTAssertEqual(result.allHTTPHeaderFields!["Content-Type"], "user-content-type")
        } catch {
            XCTFail("Unexpected error:" + error.localizedDescription)
        }
    }
}
