import XCTest
@testable import Skyflow

final class skyflow_iOS_utilTests: XCTestCase {
    override func setUp() {
    }
    
    override func tearDown() {
    }
    
    func testGetFirstRegexMatch() {
        do {
            XCTAssertEqual(try "abcdef".getFirstRegexMatch(of: "..$", contextOptions: ContextOptions()), "ef")
        } catch {
            XCTFail()
        }
        
        do {
            try "abcdef".getFirstRegexMatch(of: "9$", contextOptions: ContextOptions())
            XCTFail()
        } catch {
            XCTAssertEqual((error as! SkyflowError).code, ErrorCodes.REGEX_MATCH_FAILED(value: "9$").code)
            XCTAssert((error as! SkyflowError).localizedDescription.contains( ErrorCodes.REGEX_MATCH_FAILED(value: "9$").description))
        }
    }
    
    func testGetFormattedText() {
        XCTAssertEqual("2022".getFormattedText(with: "..$", contextOptions: ContextOptions(logLevel: .WARN)), "22")
        XCTAssertEqual("abcdef".getFormattedText(with: "9$", contextOptions: ContextOptions()), "abcdef")
        
        XCTAssertEqual("1".getFormattedText(with: "^([0-9])$", replacementString: "0$1", contextOptions: ContextOptions()), "01")
        XCTAssertEqual("12".getFormattedText(with: "^([0-9])$", replacementString: "0$1", contextOptions: ContextOptions()), "12")
    }
}
