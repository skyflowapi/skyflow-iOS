
import XCTest
@testable import Skyflow

// swiftlint:disable:next type_body_length
class skyflow_iOS_containerTests: XCTestCase {
    var collectContainer = Container<CollectContainer>(skyflow: Client(Configuration(tokenProvider: DemoTokenProvider())))
    var revealContainer = Container<RevealContainer>(skyflow: Client(Configuration(tokenProvider: DemoTokenProvider())))
    
    override func setUp() {
        self.collectContainer = Container<CollectContainer>(skyflow: Client(Configuration(tokenProvider: DemoTokenProvider())))
        self.revealContainer = Container<RevealContainer>(skyflow: Client(Configuration(tokenProvider: DemoTokenProvider())))
    }

    func testCreate() {
        let element = self.collectContainer.create(input: CollectElementInput(type: .INPUT_FIELD))
        
        XCTAssertEqual(self.collectContainer.elements.count, 1)
        XCTAssertEqual(element, self.collectContainer.elements[0])
    }
    
    func testCollectNoVaultIdAndUrl() {
        
    }
}
