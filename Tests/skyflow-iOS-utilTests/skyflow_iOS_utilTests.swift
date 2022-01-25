import XCTest
@testable import Skyflow

final class skyflow_iOS_utilTests: XCTestCase {
    override func setUp() {
    }
    
    override func tearDown() {
    }
    
    func testGetRegexMatch() {
        XCTAssertEqual("abcdef".getFirstRegexMatch(of: "..$", contextOptions: ContextOptions()), "ef")
        XCTAssertEqual("abcdef".getFirstRegexMatch(of: "9$", contextOptions: ContextOptions()), "")
    }
}
