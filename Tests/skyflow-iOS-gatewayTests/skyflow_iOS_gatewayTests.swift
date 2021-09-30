import XCTest
@testable import Skyflow

final class skyflow_iOS_gatewayTests: XCTestCase {
    
    var skyflow: Client!
    
    override func setUp() {
        self.skyflow = Client(Configuration(vaultID: "ffe21f44f68a4ae3b4fe55ee7f0a85d6", vaultURL: "https://na1.area51.vault.skyflowapis.com/", tokenProvider: DemoTokenProvider()))
    }
    
    override func tearDown() {
        skyflow = nil
    }
    
    func testCreateGatewayConfig() {
        let url = "https://sb.area51.gateway.skyflowapis.dev/v1/outboundIntegrations/abc-1212"
        let gatewayConfig = GatewayConfig(gatewayURL: url, method: .GET)
        XCTAssertEqual(gatewayConfig.gatewayURL, url)
        XCTAssertEqual(gatewayConfig.method, .GET)
        XCTAssertNil(gatewayConfig.pathParams)
        XCTAssertNil(gatewayConfig.queryParams)
        XCTAssertNil(gatewayConfig.requestBody)
        XCTAssertNil(gatewayConfig.requestHeader)
        XCTAssertNil(gatewayConfig.responseBody)
    }
    
    func testCheckPrimitive() {
        XCTAssertEqual(ConversionHelpers.checkIfPrimitive("123"), true)
        XCTAssertEqual(ConversionHelpers.checkIfPrimitive(123), true)
        XCTAssertEqual(ConversionHelpers.checkIfPrimitive(12.34), true)
        XCTAssertEqual(ConversionHelpers.checkIfPrimitive(false), true)
        XCTAssertEqual(ConversionHelpers.checkIfPrimitive([1,2,3]), false)
        XCTAssertEqual(ConversionHelpers.checkIfPrimitive(UIColor.red), false)
    }
    
    func testConvertJSONValues() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)

        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        
        let styles = Styles(base: bstyle)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", inputStyles: styles, placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput, options: options) as! TextField
        cardNumber.textField.secureText = "4111-1111-1111-1111"
        
        let revealInput = RevealElementInput(token: "abc", inputStyles: styles, label: "reveal", redaction: .DEFAULT, altText: "reveal")
        let revealElement = revealContainer?.create(input: revealInput)
        
        let customArray: [Any] = ["abc", "def", 12, "4111-1111-1111-1111"]
        
        let requestBody: [String: Any] = [
            "card_number": cardNumber,
            "holder_name": "john doe",
            "array": ["abc", "def", 12, cardNumber],
            "bool": true,
            "float": 12.234,
            "Int": 1234,
            "reveal": revealElement as! Label,
            "nestedFields": [
                "card_number": cardNumber,
                "reveal": revealElement
            ]
        ]
        
        do {
            let result = try ConversionHelpers.convertJSONValues(requestBody)
            XCTAssertEqual(result["card_number"] as! String, "4111-1111-1111-1111")
            XCTAssertEqual(result["holder_name"] as! String, "john doe")
            XCTAssertEqual(result["reveal"] as! String, "reveal")
            XCTAssertEqual((result["nestedFields"] as! [String: Any])["card_number"] as? String, "4111-1111-1111-1111")
            XCTAssertEqual(result["bool"] as! Bool, true)
            
            let resultArray = result["array"] as! [Any]
            
            XCTAssertEqual(resultArray[0] as! String, "abc")
            XCTAssertEqual(resultArray[2] as! Int, 12)
            XCTAssertEqual(resultArray[3] as! String, "4111-1111-1111-1111")
            XCTAssertEqual((result["nestedFields"] as! [String: Any])["reveal"] as? String, "reveal")
        }
        catch {
            XCTFail()
        }
        
    }
    
    func testConvertJSONValuesWithoutNestedFields() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)

        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        
        let styles = Styles(base: bstyle)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", inputStyles: styles, placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput, options: options) as! TextField
        cardNumber.textField.secureText = "4111-1111-1111-1111"
        
        let revealInput = RevealElementInput(token: "abc", inputStyles: styles, label: "reveal", redaction: .DEFAULT, altText: "reveal")
        let revealElement = revealContainer?.create(input: revealInput)
        
        let responseBody: [String: Any] = [
            "card_number": cardNumber,
            "holder_name": "john doe",
            "reveal": revealElement as Any,
            "nestedFields": [
                "card_number": cardNumber,
                "reveal": revealElement as Any
            ]
        ]
        
        do {
            try ConversionHelpers.convertJSONValues(responseBody, false)
            XCTFail()
        }
        catch {
        }
        
    }
    
    func testConvertJSONFailsForArrays() {
        let responseBody: [String: Any] = [
            "bool": true,
            "holder_name": "john doe",
            "array": [12, "string", true]
        ]
        
        do {
            try ConversionHelpers.convertJSONValues(responseBody, false, false)
            XCTFail()
        }
        catch {}

    }

    
    func testConvertJSONValuesWithInvalidValueType() {
        let responseBody: [String: Any] = [
            "invalidField": UIColor.blue
        ]
        
        do {
            try ConversionHelpers.convertJSONValues(responseBody)

            XCTFail()
        }
        catch {
        }
    }
    
    func testInvokeGateway() {
        // Incomplete
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)

        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        
        let styles = Styles(base: bstyle)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", inputStyles: styles, placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput, options: options) as! TextField
        cardNumber.textField.secureText = "4111-1111-1111-1111"
        
        let revealInput = RevealElementInput(token: "abc", inputStyles: styles, label: "reveal", redaction: .DEFAULT, altText: "reveal")
        let revealElement = revealContainer?.create(input: revealInput)
        
        let requestBody: [String: Any] = [
            "card_number": cardNumber,
            "holder_name": "john doe",
            "reveal": revealElement as Any,
            "nestedFields": [
                "card_number": cardNumber,
                "reveal": revealElement as Any
            ]
        ]
        
        let gatewayConfig = GatewayConfig(gatewayURL: "https://skyflow.com/", method: .POST, requestBody: requestBody)
        
        self.skyflow.invokeGateway(config: gatewayConfig, callback: DemoAPICallback(expectation: XCTestExpectation(description: "should return response")))

    }
    
    func testAddParams() {
        do{
            let modifiedUrl = try RequestHelpers.addPathParams("https://www.skyflow.com/{param}/", ["param": "vault"])
            XCTAssertEqual(modifiedUrl, "https://www.skyflow.com/vault/")

        }
        catch {
            XCTFail()
        }
        
    }
    
    func testAddQueryParams() {
        do{
            let modifiedUrl = try RequestHelpers.addQueryParams("https://www.skyflow.com/", ["param": "vault"])
            XCTAssertEqual(modifiedUrl.absoluteString, "https://www.skyflow.com?param=vault")

        }
        catch {
            XCTFail()
        }
        
    }
    
    func testResponseParse(){
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        let styles = Styles(base: bstyle)
        let cvvRevealInput = RevealElementInput(token: "cvv", inputStyles: styles, label: "reveal", redaction: .DEFAULT, altText: "Not yet generated")
        let cardNumberRevealInput = RevealElementInput(token: "cardNumber", inputStyles: styles, label: "reveal", redaction: .DEFAULT, altText: "Not yet generated")
        let cvvElement = revealContainer?.create(input: cvvRevealInput)
        let cardNumberElement = revealContainer?.create(input: cardNumberRevealInput)
        let responseBody: [String: Any] = [
            "resource" : [
                "cvv2": cvvElement,
                "cardDetails": [
                    "cardNumber" : cardNumberElement
                ]
            ]
        ]
        
        do {
            var paths = RequestHelpers.parseResponse(response: responseBody)
            print("paths", paths)
            XCTAssertEqual(paths.count, 2)
            XCTAssertEqual(paths[0], "resource.cvv2")
            XCTAssertEqual(paths[1], "resource.cardDetails.cardNumber")
//            XCTAssertEqual(cvvElement?.getValue().count, 3)
        }
        catch {
            XCTFail()
        }
    }
    
    func testResponseParseAndUpdate(){
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        let styles = Styles(base: bstyle)
        let cvvRevealInput = RevealElementInput(token: "cvv", inputStyles: styles, label: "reveal", redaction: .DEFAULT, altText: "Not yet generated")
        let cardNumberRevealInput = RevealElementInput(token: "cardNumber", inputStyles: styles, label: "reveal", redaction: .DEFAULT, altText: "Not yet generated")
        let cvvElement = revealContainer?.create(input: cvvRevealInput)
        let cardNumberElement = revealContainer?.create(input: cardNumberRevealInput)
        let responseBody: [String: Any] = [
            "resource" : [
                "cvv2": cvvElement,
                "cardDetails": [
                    "cardNumber" : cardNumberElement
                ]
            ]
        ]
        let response: [String: Any] = [
            "resource" : [
                "cvv2": "456",
                "cardDetails": [
                    "cardNumber" : "4111 1111 1111 1112"
                ]
            ]
        ]
        let paths = ["resource.cvv2", "resource.cardDetails.cardNumber"]
        
        do {
            RequestHelpers.updateElementsWithResponse(paths: paths, response: response, responseBody: responseBody)
            print("cvvElement", cvvElement?.getValue())
            print("cardNumberElement", cardNumberElement?.getValue())
            XCTAssertEqual(cvvElement?.getValue(), "456")
            XCTAssertEqual(cardNumberElement?.getValue(), "4111 1111 1111 1111")
        }
        catch {
            XCTFail()
        }
    }
}
