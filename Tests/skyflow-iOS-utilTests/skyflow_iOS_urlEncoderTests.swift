import XCTest
@testable import Skyflow


final class skyflow_iOS_urlEncoderTests: XCTestCase {
    
    func testEncodeKey() {
        let parents = ["card", "numbers", 0] as [Any]
        
        let encodedKey = UrlEncoder.encodeKey(parents)
        
        XCTAssertEqual(encodedKey, "card[numbers][0]")
    }
    
        
    func testEncodeSimpleJson() {
        let json = [
            "key1": "value1",
            "key2": "value2"
        ]
        
        let encodedJson = UrlEncoder.encodeSimpleJson(json: json)
        
        XCTAssert(encodedJson.contains("&"))
        XCTAssert(encodedJson.contains("key1=value1"))
        XCTAssert(encodedJson.contains("key2=value2"))
    }
    
    func testEncodeSimple() {
        let json = [
            "key1": "value1",
            "key2": "value2"
        ]
        
        let encodedJson = UrlEncoder.encode(json: json)
        
        XCTAssert(encodedJson.contains("&"))
        XCTAssert(encodedJson.contains("key1=value1"))
        XCTAssert(encodedJson.contains("key2=value2"))
    }
    
    func testEncodeJsonArray() {
        let json = [
            "type": "card",
            "card": ["1", 2, "and", "ok"]
        ] as [String: Any]
        
        let encodedJson = UrlEncoder.encode(json: json)
        
        XCTAssert(encodedJson.contains("type=card"))
        XCTAssert(encodedJson.contains("card%5B0%5D=1"))
        XCTAssert(encodedJson.contains("card%5B1%5D=2"))
        XCTAssert(encodedJson.contains("card%5B2%5D=and"))
        XCTAssert(encodedJson.contains("card%5B3%5D=ok"))
    }
    
    func testEncodeJsonNested() {
        let json = [
            "type": "card",
            "card": [
                "number": "4242424242424242",
                "exp_month": 1,
                "exp_year": 2023,
                "cvc": 314
            ]
        ] as [String: Any]
        
        let encodedJson = UrlEncoder.encode(json: json)
        
        XCTAssert(encodedJson.contains("type=card"))
        XCTAssert(encodedJson.contains("card%5Bnumber%5D=4242424242424242"))
        XCTAssert(encodedJson.contains("card%5Bexp_month%5D=1"))
        XCTAssert(encodedJson.contains("card%5Bexp_year%5D=2023"))
        XCTAssert(encodedJson.contains("card%5Bcvc%5D=314"))
    }
}
