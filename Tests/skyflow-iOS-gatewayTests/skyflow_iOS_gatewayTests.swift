import XCTest
@testable import Skyflow

final class skyflow_iOS_collectTests: XCTestCase {
    
    var skyflow: Client!
    
    override func setUp() {
        self.skyflow = Client(Configuration(vaultID: "ffe21f44f68a4ae3b4fe55ee7f0a85d6", vaultURL: "https://na1.area51.vault.skyflowapis.com/", tokenProvider: DemoTokenProvider()))
    }
    
    override func tearDown() {
        skyflow = nil
    }
    
    func testCreateGatewayConfig() {
        let url = "https://sb.area51.gateway.skyflowapis.dev/v1/outboundIntegrations/abc-1212"
        let gatewayConfig = GatewayConfig(gatewayURL: url, method: "GET")
        XCTAssertEqual(gatewayConfig.gatewayURL, url)
        XCTAssertEqual(gatewayConfig.method, "GET")
        XCTAssertNil(gatewayConfig.pathParams)
        XCTAssertNil(gatewayConfig.queryParams)
        XCTAssertNil(gatewayConfig.requestBody)
        XCTAssertNil(gatewayConfig.requestHeader)
        XCTAssertNil(gatewayConfig.responseBody)
    }
}
