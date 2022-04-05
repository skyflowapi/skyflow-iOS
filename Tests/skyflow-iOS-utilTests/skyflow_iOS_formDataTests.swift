import XCTest
@testable import Skyflow


final class skyflow_iOS_formDataTests: XCTestCase {
    private var formRequest = MultipartFormDataRequest(url: URL(string: "https://example.com")!)
    override func setUp() {
        self.formRequest = MultipartFormDataRequest(url: URL(string: "https://www.example.com")!)
    }
    
    func testAddTextField() {
        let name = "number"
        let value = "4111-1111-1111-1111"
        self.formRequest.addTextField(named: name, value: value)
        
        let request = formRequest.asURLRequest(with: [:])
        XCTAssertNotNil(request.httpBody)
        XCTAssert(String(data: request.httpBody!, encoding: .utf8)!.contains("Content-Disposition: form-data; name=\"\(name)\"\r\n"))
        XCTAssert(String(data: request.httpBody!, encoding: .utf8)!.contains("\(value)\r\n"))
//        XCTAssert(String(data: request.httpBody!, encoding: .utf8)!.contains("Content-Type: text/plain"))
    }
    
    func testAddValues() {
        
        let values = [
            "name": "value",
            "nested[card]": "true"
        ]
        self.formRequest.addValues(json: values)
        
        let request = formRequest.asURLRequest(with: [:])
        XCTAssertNotNil(request.httpBody)
        XCTAssert(String(data: request.httpBody!, encoding: .utf8)!.contains("Content-Disposition: form-data; name=\"name\"\r\n"))
        XCTAssert(String(data: request.httpBody!, encoding: .utf8)!.contains("value\r\n"))
        
        XCTAssert(String(data: request.httpBody!, encoding: .utf8)!.contains("Content-Disposition: form-data; name=\"nested[card]\"\r\n"))
        XCTAssert(String(data: request.httpBody!, encoding: .utf8)!.contains("true\r\n"))
    }
    
    func testAddValuesWithEncoder() {
        let nestedValues = [
            "name": "value",
            "nested": [
                "card": "true",
                "number": 23
            ]
        ] as [String: Any]
        var parents = [Any]()
        var pairs = [:] as [String : String]
        
        let values = UrlEncoder.encodeByType(parents: &parents, pairs: &pairs, data: nestedValues)
        self.formRequest.addValues(json: values)
        
        let request = formRequest.asURLRequest(with: [:])
        XCTAssertNotNil(request.httpBody)
        XCTAssert(String(data: request.httpBody!, encoding: .utf8)!.contains("Content-Disposition: form-data; name=\"name\"\r\n"))
        XCTAssert(String(data: request.httpBody!, encoding: .utf8)!.contains("value\r\n"))
        
        XCTAssert(String(data: request.httpBody!, encoding: .utf8)!.contains("Content-Disposition: form-data; name=\"nested[card]\"\r\n"))
        XCTAssert(String(data: request.httpBody!, encoding: .utf8)!.contains("true\r\n"))
        
        XCTAssert(String(data: request.httpBody!, encoding: .utf8)!.contains("Content-Disposition: form-data; name=\"nested[number]\"\r\n"))
        XCTAssert(String(data: request.httpBody!, encoding: .utf8)!.contains("23\r\n"))
    }
}
