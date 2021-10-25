import XCTest
@testable import Skyflow

final class skyflow_iOS_gatewayTests: XCTestCase {
    var skyflow: Client!

    override func setUp() {
        self.skyflow = Client(Configuration(vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!, vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!, tokenProvider: DemoTokenProvider()))
    }
    
    override func tearDown() {
        skyflow = nil
    }
    
//    func testCardIssuanceGatewayIntegration(){
//
//        let window = UIWindow()
//
//        let revealContainer = self.skyflow?.container(type: Skyflow.ContainerType.REVEAL, options: nil)
//
//        let revealCardNumberInput = RevealElementInput(token: "1815-6223-1073-1425", inputStyles: Styles(), label: "Card Number", redaction: .DEFAULT)
//
//        let revealCardNumber = revealContainer?.create(input: revealCardNumberInput, options: RevealElementOptions())
//
//        window.addSubview(revealCardNumber!)
//
//        let revealCVVInput = RevealElementInput(inputStyles: Styles(), label: "cvv", redaction: Skyflow.RedactionType.PLAIN_TEXT, altText: "Cvv not yet generated")
//
//        let revealCVV = revealContainer?.create(input: revealCVVInput)
//
//        window.addSubview(revealCVV!)
//
//        let url = "https://sb.area51.gateway.skyflowapis.dev/v1/gateway/outboundRoutes/\(ProcessInfo.processInfo.environment["CVV_INTEGRATION_ID"]!)/dcas/cardservices/v1/cards/{card_id}/cvv2generation"
//        let pathParams = ["card_id": "1815-6223-1073-1425"]
//        let requestHeaders = ["Content-Type": "application/json ","Authorization": ProcessInfo.processInfo.environment["VISA_BASIC_AUTH"]!]
//        let requestBody = [
//            "expirationDate": [
//                "mm": "12",
//                "yy": "22"
//            ]]
//
//        let responseBody = [
//            "resource": [
//                "cvv2": revealCVV
//            ]]
//
//        let gatewayConfig = GatewayConfig(gatewayURL: url, method: .POST, pathParams: pathParams as [String : Any], requestBody: requestBody, requestHeader: requestHeaders, responseBody: responseBody)
//
//        let expectation = XCTestExpectation(description: "Card issuance invoke gateway")
//
//        let callback = DemoAPICallback(expectation: expectation)
//
//        skyflow?.invokeGateway(config: gatewayConfig, callback: callback)
//
//        wait(for: [expectation], timeout: 30.0)
//    }
    
    func testGatewayIntegrationInvalidId(){
        
        let window = UIWindow()
        
        let revealContainer = self.skyflow?.container(type: Skyflow.ContainerType.REVEAL, options: nil)
                    
        let revealCardNumberInput = RevealElementInput(token: "1815-6223-1073-1425", inputStyles: Styles(), label: "Card Number", redaction: .DEFAULT)
                    
        let revealCardNumber = revealContainer?.create(input: revealCardNumberInput, options: RevealElementOptions())
        
        window.addSubview(revealCardNumber!)
        
        let revealCVVInput = RevealElementInput(inputStyles: Styles(), label: "cvv", redaction: Skyflow.RedactionType.PLAIN_TEXT, altText: "Cvv not yet generated")
                    
        let revealCVV = revealContainer?.create(input: revealCVVInput)
        
        window.addSubview(revealCVV!)
        
        let url = "https://sb.area51.gateway.skyflowapis.dev/v1/gateway/outboundRoutes/invalidID/dcas/cardservices/v1/cards/{card_id}/cvv2generation"
        let pathParams = ["card_id": "1815-6223-1073-1425"]
        let requestHeaders = ["Content-Type": "application/json ","Authorization": ProcessInfo.processInfo.environment["VISA_BASIC_AUTH"]!]
        let requestBody = [
            "expirationDate": [
                "mm": "12",
                "yy": "22"
            ]]
        
        let responseBody = [
            "resource": [
                "cvv2": revealCVV
            ]]
        
        let gatewayConfig = GatewayConfig(gatewayURL: url, method: .POST, pathParams: pathParams as [String : Any], requestBody: requestBody, requestHeader: requestHeaders, responseBody: responseBody)
        
        let expectation = XCTestExpectation(description: "Card issuance invoke gateway")
        
        let callback = DemoAPICallback(expectation: expectation)
        
        skyflow?.invokeGateway(config: gatewayConfig, callback: callback)
        
        wait(for: [expectation], timeout: 30.0)
        
        let errorMessage = ((callback.data["errors"] as? [Error])?[0])?.localizedDescription
        
        XCTAssertNotNil(errorMessage?.contains("failed to fetch intergration"))
    }
//    
//    func testPullFundsGatewayIntegration(){
//        
//        let window = UIWindow()
//        
//        let collectContainer = self.skyflow?.container(type: Skyflow.ContainerType.COLLECT, options: nil)
//        
//        let revealContainer = self.skyflow?.container(type: Skyflow.ContainerType.REVEAL, options: nil)
//        
//        let cardNumberInput = CollectElementInput(table: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
//        
//        let cardNumberElement = collectContainer?.create(input: cardNumberInput)
//        
//        cardNumberElement?.actualValue = "4895142232120006"
//        
//        window.addSubview(cardNumberElement!)
//        
//        let expirationDateInput = RevealElementInput(token: "a1142154-ab16-4484-be65-25cd878aadf7", inputStyles: Styles(), label: "expiration date")
//                    
//        let expirationDateElement = revealContainer?.create(input: expirationDateInput)
//        
//        window.addSubview(expirationDateElement!)
//        
//        let transactionIdentifierInput = RevealElementInput(inputStyles: Styles(), label: "transaction identifier", altText: "Transaction not yet completed")
//                    
//        let transactionIdentifierElement = revealContainer?.create(input: transactionIdentifierInput)
//        
//        window.addSubview(transactionIdentifierElement!)
//        
//        let url = "https://sb.area51.gateway.skyflowapis.dev/v1/gateway/outboundRoutes/\(ProcessInfo.processInfo.environment["PULL_FUNDS_INTEGRATION_ID"]!)/visadirect/fundstransfer/v1/pullfundstransactions"
//        let requestHeaders = ["Content-Type": "application/json ","Authorization": ProcessInfo.processInfo.environment["VISA_BASIC_AUTH"]!]
//        
//        let requestBody:[String: Any] = [
//            "surcharge": "11.99",
//            "amount": "124.02",
//            "localTransactionDateTime": "2021-10-22T23:33:06",
//            "cpsAuthorizationCharacteristicsIndicator": "Y",
//            "riskAssessmentData": [
//              "traExemptionIndicator": true,
//              "trustedMerchantExemptionIndicator": true,
//              "scpExemptionIndicator": true,
//              "delegatedAuthenticationIndicator": true,
//              "lowValueExemptionIndicator": true
//            ],
//            "cardAcceptor": [
//              "address": [
//                "country": "USA",
//                "zipCode": "94404",
//                "county": "081",
//                "state": "CA"
//              ],
//              "idCode": "ABCD1234ABCD123",
//              "name": "Visa Inc. USA-Foster City",
//              "terminalId": "ABCD1234"
//            ],
//            "acquirerCountryCode": "840",
//            "acquiringBin": "408999",
//            "senderCurrencyCode": "USD",
//            "retrievalReferenceNumber": "330000550000",
//            "addressVerificationData": [
//              "street": "XYZ St",
//              "postalCode": "12345"
//            ],
//            "cavv": "0700100038238906000013405823891061668252",
//            "systemsTraceAuditNumber": "451001",
//            "businessApplicationId": "AA",
//            "senderPrimaryAccountNumber": cardNumberElement,
//            "settlementServiceIndicator": "9",
//            "visaMerchantIdentifier": "73625198",
//            "foreignExchangeFeeTransaction": "11.99",
//            "senderCardExpiryDate": expirationDateElement,
//            "nationalReimbursementFee": "11.22"
//          ]
//        
//        let responseBody = [
//            "resource": [
//                "transactionIdentifier": transactionIdentifierElement
//            ]]
//        
//        let gatewayConfig = GatewayConfig(gatewayURL: url, method: .POST, requestBody: requestBody, requestHeader: requestHeaders, responseBody: responseBody)
//        
//        let expectation = XCTestExpectation(description: "Pull funds invoke gateway")
//        
//        let callback = DemoAPICallback(expectation: expectation)
//        
//        skyflow?.invokeGateway(config: gatewayConfig, callback: callback)
//        
//        wait(for: [expectation], timeout: 30.0)
//    }

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
            let result = try ConversionHelpers.convertJSONValues(requestBody, contextOptions: ContextOptions())
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
            try ConversionHelpers.convertJSONValues(responseBody, false, contextOptions: ContextOptions())
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
            try ConversionHelpers.convertJSONValues(responseBody, false, false, contextOptions: ContextOptions())
            XCTFail()
        } catch {}
    }


    func testConvertJSONValuesWithInvalidValueType() {
        let responseBody: [String: Any] = [
            "invalidField": UIColor.blue
        ]

        do {
            try ConversionHelpers.convertJSONValues(responseBody, contextOptions: ContextOptions())

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
            let modifiedUrl = try RequestHelpers.addPathParams(
                "https://sb.area51.gateway.skyflowapis.dev/v1/gateway/outboundRoutes/\(ProcessInfo.processInfo.environment["CVV_INTEGRATION_ID"]!)/dcas/cardservices/v1/cards/{card_id}/cvv2generation", ["card_id": "12345"],
                contextOptions: ContextOptions())
            XCTAssertEqual(
                modifiedUrl,
                "https://sb.area51.gateway.skyflowapis.dev/v1/gateway/outboundRoutes/\(ProcessInfo.processInfo.environment["CVV_INTEGRATION_ID"]!)/dcas/cardservices/v1/cards/12345/cvv2generation")
        } catch {
            XCTFail()
        }
    }


    func testAddQueryParams() {
        do {
            let modifiedUrl = try RequestHelpers.addQueryParams("https://www.skyflow.com/", ["param": "vault"], contextOptions: ContextOptions())
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

        let revealInput = RevealElementInput(token: "abc", inputStyles: styles, label: "reveal", altText: "reveal")
        let revealElement: Label? = revealContainer?.create(input: revealInput)


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
            let convertedResponse = try RequestHelpers.parseActualResponseAndUpdateElements(response: response, responseBody: responseBody, contextOptions: ContextOptions())

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
            XCTAssertEqual(try RequestHelpers.traverseAndConvert(response: response, responseBody: responseBody, key: "expirationDate", contextOptions: ContextOptions()) as! String, "12/22")
            let cardConvert = try RequestHelpers.traverseAndConvert(response: response, responseBody: responseBody, key: "card_number", contextOptions: ContextOptions())
            XCTAssertNil(cardConvert)
        } catch {
            XCTFail()
        }
    }

    func testURLWithArrayParams() {
        do {
            let url = try RequestHelpers.createRequestURL(baseURL: "https://www.skyflow.com", pathParams: nil, queryParams: ["array": ["abcd", 123, 12.23, true]], contextOptions: ContextOptions())
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
            let result = try ConversionHelpers.removeEmptyValuesFrom(response: response, contextOptions: ContextOptions())
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
        XCTAssertEqual(error.code, 400)
        XCTAssertEqual(error.localizedDescription, "Vault ID Vault#123 is invalid")
    }

    func testGetInvalidResponseKeys() {
        let responseBody: [String: Any] = [
            "key1": "value",
            "key2": "value",
            "key3": "value",
            "nested": [
                "key1": "value",
                "key2": "value"
            ],
            "nosuchkey": [
                "key": "value"
            ]
        ]

        let response: [String: Any] = [
            "key1": "value",
            "key2": "value",
            "nested": [
                "key1": "value"
            ]
        ]

        let result = RequestHelpers.getInvalidResponseKeys(responseBody, response, contextOptions: ContextOptions())
        let errors: [ErrorCodes] = [
            .MISSING_KEY_IN_RESPONSE(value: "key3"),
            .MISSING_KEY_IN_RESPONSE(value: "nested.key2"),
            .MISSING_KEY_IN_RESPONSE(value: "nosuchkey")
        ]
        for error in errors {
            XCTAssert(result.contains(error.errorObject))
        }
    }
    
    func testStringifyDict() {
        let dict: [String: Any] = ["int": 2, "str": "abc", "double": 2.3, "bool": false, "true": true, "array": [1, "abc", true, 23.0]]
        let stringifiedDict = ConversionHelpers.stringifyDict(dict)
        
        XCTAssertNotNil(stringifiedDict)
        
        if let stringified = stringifiedDict {
            XCTAssertEqual(stringified["int"] as! String, "2")
            XCTAssertEqual(stringified["str"] as! String, "abc")
            XCTAssertEqual(stringified["double"] as! String, "2.3")
            XCTAssertEqual(stringified["bool"] as! String, "false")
            XCTAssertEqual(stringified["true"] as! String, "true")
            let resultarray = stringified["array"] as! [Any]
            XCTAssertEqual(resultarray[0] as! Int, 1)
            XCTAssertEqual(resultarray[1] as! String, "abc")
            XCTAssertEqual(resultarray[2] as! Bool, true)
            XCTAssertEqual(resultarray[3] as! Double, 23.0)
        }
    }
    
    func testConvertOrFail() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)

        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)

        let styles = Styles(base: bstyle)

        let options = CollectElementOptions(required: false)

        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", inputStyles: styles, placeholder: "card number", type: .CARD_NUMBER)

        let cardNumber = container?.create(input: collectInput, options: options) as! TextField
        cardNumber.textField.secureText = "4111-1111-1111-1111"

        let revealInput = RevealElementInput(token: "abc", inputStyles: styles, label: "reveal", altText: "reveal")
        let revealElement: Label? = revealContainer?.create(input: revealInput)


        let requestBody: [String: Any] = [
            "resource": [
                "card_number": cardNumber,
                "reveal": revealElement!,
                "nestedFields": [
                    "reveal": revealElement
                ]
            ],
            "expirationDate": "12/22"
        ]

        do {
            let converted = try ConversionHelpers.convertOrFail(requestBody, contextOptions: ContextOptions())
        }
        catch {
            XCTFail()
        }

    }
    
}
