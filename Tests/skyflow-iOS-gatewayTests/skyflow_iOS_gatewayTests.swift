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
        XCTAssertEqual(ConversionHelpers.checkIfPrimitive([1, 2, 3]), false)
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
        cardNumber.actualValue = "4111-1111-1111-1111"

        let revealInput = RevealElementInput(token: "abc", inputStyles: styles, label: "reveal", redaction: .DEFAULT, altText: "reveal")
        let revealElement = revealContainer?.create(input: revealInput)

        let customArray: [Any] = ["abc", "def", 12, "4111-1111-1111-1111"]

        let requestBody: [String: Any] = [
            "card_number": cardNumber,
            "holder_name": "john doe",
            "array": ["abc", "def", 12],
            "bool": true,
            "float": 12.234,
            "Int": 1234,
            "reveal": revealElement as! Label
//            "nestedFields": [
//                "card_number": cardNumber,
//                "reveal": revealElement
//            ]
        ]

        do {
            let result = try ConversionHelpers.convertJSONValues(requestBody)
            XCTAssertEqual(result["card_number"] as! String, "4111-1111-1111-1111")
            XCTAssertEqual(result["holder_name"] as! String, "john doe")
            XCTAssertEqual(result["reveal"] as! String, "abc")
//            XCTAssertEqual((result["nestedFields"] as! [String: Any])["card_number"] as? String, "4111-1111-1111-1111")
            XCTAssertEqual(result["bool"] as! Bool, true)

            let resultArray = result["array"] as! [Any]

            XCTAssertEqual(resultArray[0] as! String, "abc")
            XCTAssertEqual(resultArray[2] as! Int, 12)
//            XCTAssertEqual(resultArray[3] as! String, "4111-1111-1111-1111")
//            XCTAssertEqual((result["nestedFields"] as! [String: Any])["reveal"] as? String, "reveal")
        } catch {
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
        } catch {
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
        } catch {}
    }


    func testConvertJSONValuesWithInvalidValueType() {
        let responseBody: [String: Any] = [
            "invalidField": UIColor.blue
        ]

        do {
            try ConversionHelpers.convertJSONValues(responseBody)

            XCTFail()
        } catch {
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
        do {
            let modifiedUrl = try RequestHelpers.addPathParams("https://sb.area51.gateway.skyflowapis.dev/v1/gateway/outboundRoutes/bf9b3f06-e1ba-4ef2-8758-9409c735859e/dcas/cardservices/v1/cards/{card_id}/cvv2generation", ["card_id": "12345"])
            XCTAssertEqual(modifiedUrl, "https://sb.area51.gateway.skyflowapis.dev/v1/gateway/outboundRoutes/bf9b3f06-e1ba-4ef2-8758-9409c735859e/dcas/cardservices/v1/cards/12345/cvv2generation")
        } catch {
            XCTFail()
        }
    }
    

    func testAddQueryParams() {
        do {
            let modifiedUrl = try RequestHelpers.addQueryParams("https://www.skyflow.com/", ["param": "vault"])
            XCTAssertEqual(modifiedUrl.absoluteString, "https://www.skyflow.com?param=vault")
        } catch {
            XCTFail()
        }
    }

    func testParseActualResponseAndUpdateElements() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)

        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)

        let styles = Styles(base: bstyle)

        let options = CollectElementOptions(required: false)

        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", inputStyles: styles, placeholder: "card number", type: .CARD_NUMBER)

        let cardNumber = container?.create(input: collectInput, options: options) as! TextField
        cardNumber.textField.secureText = "4111-1111-1111-1111"

        let revealInput = RevealElementInput(token: "abc", inputStyles: styles, label: "reveal", redaction: .DEFAULT, altText: "reveal")
        let revealElement: Label? = revealContainer?.create(input: revealInput)

        let customArray: [Any] = ["abc", "def", 12, "4111-1111-1111-1111"]

        let responseBody: [String: Any] = [
            "resource": [
                "card_number": cardNumber,
                "reveal": revealElement!,
                "nestedFields": [
                    "reveal": revealElement
                ]
            ],
            "expirationDate": "12/22"
        ]

        let response: [String: Any] = [
            "resource": [
                "card_number": "cardNumber",
                "reveal": "1234",
                "nestedFields": [
                    "card_number": "4111-1111-1111-1111",
                    "reveal": "abcd"
                ]
            ],
            "expirationDate": "12/22"
        ]


        do {
            let convertedResponse = try RequestHelpers.parseActualResponseAndUpdateElements(response: response, responseBody: responseBody)

            XCTAssertEqual(convertedResponse["expirationDate"] as! String, "12/22")
            XCTAssertNil((convertedResponse["resource"] as! [String: Any])["card_number"])
            XCTAssertNil((convertedResponse["resource"] as! [String: Any])["reveal"])
            // XCTAssertEqual(cardNumber.getValue(), "cardNumber")
            // XCTAssertEqual(revealElement?.getValue(), "1234")

        } catch {
            XCTFail()
        }
    }

    func testConvertValue() {
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
                "reveal": revealElement as! Label,
                "nestedFields": [
                    "card_number": cardNumber,
                    "reveal": revealElement
                ],
            "expirationDate": "12/22"
        ]

        let response: [String: Any] = [
                "card_number": "cardNumber",
                "reveal": "1234",
                "nestedFields": [
                    "card_number": "4111-1111-1111-1111",
                    "reveal": "revealElement"
                ],
            "expirationDate": "12/22"
        ]

        do {
            XCTAssertEqual(try RequestHelpers.traverseAndConvert(response: response, responseBody: responseBody, key: "expirationDate") as! String, "12/22")
            let cardConvert = try RequestHelpers.traverseAndConvert(response: response, responseBody: responseBody, key: "card_number")
            XCTAssertNil(cardConvert)
        } catch {
            XCTFail()
        }
    }

    func testURLWithArrayParams() {
        do {
            let url = try RequestHelpers.createRequestURL(baseURL: "https://www.skyflow.com", pathParams: nil, queryParams: ["array": ["abcd", 123, 12.23, true]])
            XCTAssertEqual(url.absoluteString, "https://www.skyflow.com?array=abcd&array=123&array=12.23&array=true")
        } catch {
            XCTFail()
        }
    }

    func testConvertParamArrays() {
        let params: [String: Any] = ["abc": "def", "arr": [1, 2, 3, 5], "mixedArr": [1, "@", "aer3", 23.4, true], "withCommas": ["23,,,", "abcd", true, 234]]
        let result = ConversionHelpers.convertParamArrays(params: params)

        XCTAssertEqual(result["abc"] as! String, "def")
        XCTAssertEqual(result["arr"] as! String, "1,2,3,5")
        XCTAssertEqual(result["mixedArr"] as! String, "1,@,aer3,23.4,true")
        XCTAssertEqual(result["withCommas"] as! String, "23,,,,abcd,true,234")
    }

    func testCheckPresentIn() {
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

        let array = [cardNumber]
        XCTAssertEqual(ConversionHelpers.presentIn(array, value: cardNumber), true)
        XCTAssertEqual(ConversionHelpers.presentIn(array, value: revealElement), false)
    }

    func testRemoveEmptyValues() {
        let response: [String: Any] = [
            "key1": "value",
            "arr": [1, "23"],
            "empty": [],
            "nested": [
                "arr": [],
                "val": 12.23,
                "dict": ["abc": "def"],
                "emptyDict": [:]
            ],
            "emptyDict": [
                "arr": [],
                "empty": [:]
            ]
        ]

        do {
            let result = try ConversionHelpers.removeEmptyValuesFrom(response: response)
            XCTAssertEqual(result["key1"] as! String, "value")
            XCTAssertEqual((result["arr"] as! [Any])[0] as! Int, 1)
            XCTAssertEqual((result["arr"] as! [Any])[1] as! String, "23")
            XCTAssertNil(result["empty"])
            XCTAssertNil(result["emptyDict"])
            XCTAssertNil((result["nested"] as! [String: Any])["arr"])
            XCTAssertEqual((result["nested"] as! [String: Any])["val"] as! Double, 12.23)
            XCTAssertEqual(((result["nested"] as! [String: Any])["dict"] as! [String: String])["abc"], "def")
            XCTAssertNil((result["nested"] as! [String: Any])["emptyDict"])
        } catch {
            XCTFail()
        }
    }
    
    func testFormatErrorMessage() {
        let noValueReplace = ErrorCodes.EMPTY_TABLE_NAME()
        let singleValueReplace = ErrorCodes.EMPTY_VAULT(value: "vault#123")
        let multiValueReplace = ErrorCodes.INVALID_TABLE_NAME(values: ["Table#42", "Vault#666"])
        
        XCTAssertEqual(noValueReplace.description, "Table Name is empty")
        XCTAssertEqual(singleValueReplace.description, "Vault ID vault#123 is invalid")
        XCTAssertEqual(multiValueReplace.description, "Table#42 passed doesn’t exist in the vault with id Vault#666")
    }
    
    func testError() {
        let errorCode = ErrorCodes.EMPTY_VAULT(value: "Vault#123")
        let error = errorCode.errorObject
        
        XCTAssertEqual(error.domain, "")
        XCTAssertEqual(error.code, 100)
        XCTAssertEqual(error.localizedDescription, "Vault ID Vault#123 is invalid")
    }
}
