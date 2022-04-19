// swiftlint:disable file_length
import XCTest
@testable import Skyflow

// swiftlint:disable:next type_body_length
final class skyflow_iOS_connectionTests: XCTestCase {
    var skyflow: Client!
    
    override func setUp() {
        self.skyflow = Client(Configuration(
            vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!,
            vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!,
            tokenProvider: DemoTokenProvider(),
            options: Options(logLevel: .DEBUG)))
    }
    
    override func tearDown() {
        skyflow = nil
    }
    
    func waitForUIUpdates() {
        
        let expectation = self.expectation(description: "Test")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1, handler: nil)
    }
    
    
    
    func testCreateConnectionConfig() {
        let url = "\(ProcessInfo.processInfo.environment["CONNECTION_URL"]!)/abc-1212"
        let connectionConfig = ConnectionConfig(connectionURL: url, method: .GET)
        XCTAssertEqual(connectionConfig.connectionURL, url)
        XCTAssertEqual(connectionConfig.method, .GET)
        XCTAssertNil(connectionConfig.pathParams)
        XCTAssertNil(connectionConfig.queryParams)
        XCTAssertNil(connectionConfig.requestBody)
        XCTAssertNil(connectionConfig.requestHeader)
        XCTAssertNil(connectionConfig.responseBody)
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
        
        let cardNumber = container!.create(input: collectInput, options: options)
        cardNumber.actualValue = "4111-1111-1111-1111"
        
        let revealInput = RevealElementInput(token: "abc", inputStyles: styles, label: "reveal", altText: "reveal")
        let revealElement = revealContainer!.create(input: revealInput)
        
        let requestBody: [String: Any] = [
            "card_number": cardNumber,
            "holder_name": "john doe",
            "array": ["abc", "def", 12],
            "bool": true,
            "float": 12.234,
            "Int": 1234,
            "reveal": revealElement
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
        
        let cardNumber = container!.create(input: collectInput, options: options)
        cardNumber.textField.secureText = "4111-1111-1111-1111"
        
        let revealInput = RevealElementInput(token: "abc", inputStyles: styles, label: "reveal", altText: "reveal")
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
    
    func testAddParams() {
        do {
            let modifiedUrl = try RequestHelpers.addPathParams(
                "\(ProcessInfo.processInfo.environment["CONNECTION_URL"]!)/\(ProcessInfo.processInfo.environment["CVV_INTEGRATION_ID"]!)/dummy/{card_id}/dummy", ["card_id": "12345"],
                contextOptions: ContextOptions())
            XCTAssertEqual(
                modifiedUrl,
                "\(ProcessInfo.processInfo.environment["CONNECTION_URL"]!)/\(ProcessInfo.processInfo.environment["CVV_INTEGRATION_ID"]!)/dummy/12345/dummy")
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
        
        let cardNumber = container!.create(input: collectInput, options: options)
        cardNumber.textField.secureText = "4111-1111-1111-1111"
        
        let revealInput = RevealElementInput(token: "abc", inputStyles: styles, label: "reveal", altText: "reveal")
        let revealElement: Label? = revealContainer?.create(input: revealInput)
        
        
        let responseBody: [String: Any] = [
            "resource": [
                "card_number": cardNumber,
                "nestedFields": [
                    "reveal": revealElement
                ]
            ],
            "expirationDate": "12/22"
        ]
        
        let response: [String: Any] = [
            "resource": [
                "card_number": "cardNumber",
                "nestedFields": [
                    "card_number": "4111-1111-1111-1111",
                    "reveal": "abcd"
                ]
            ],
            "expirationDate": "12/22"
        ]
        
        
        do {
            let convertedResponse = try RequestHelpers.parseActualResponseAndUpdateElements(response: response, responseBody: responseBody, contextOptions: ContextOptions())
            
            waitForUIUpdates()
            
            XCTAssertEqual(convertedResponse["expirationDate"] as! String, "12/22")
            XCTAssertNil((convertedResponse["resource"] as! [String: Any])["card_number"])
            XCTAssertNil((convertedResponse["resource"] as! [String: Any])["reveal"])
             XCTAssertEqual(cardNumber.getValue(), "cardNumber")
             XCTAssertEqual(revealElement?.getValue(), "abcd")
            
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
        
        let cardNumber = container!.create(input: collectInput, options: options)
        cardNumber.textField.secureText = "4111-1111-1111-1111"
        
        let revealInput = RevealElementInput(token: "abc", inputStyles: styles, label: "reveal", altText: "reveal")
        let revealElement = revealContainer!.create(input: revealInput)
        
        
        let responseBody: [String: Any] = [
            "card_number": cardNumber,
            "reveal": revealElement,
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
        
        let cardNumber = container!.create(input: collectInput, options: options)
        cardNumber.textField.secureText = "4111-1111-1111-1111"
        
        let revealInput = RevealElementInput(token: "abc", inputStyles: styles, label: "reveal", altText: "reveal")
        let revealElement = revealContainer!.create(input: revealInput)
        
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
        
        XCTAssertEqual(noValueReplace.description, "table key cannot be empty")
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
            XCTAssert(result.contains(error.getErrorObject(contextOptions: ContextOptions())))
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
        
        let cardNumber = container!.create(input: collectInput, options: options)
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
            try ConversionHelpers.convertOrFail(requestBody, contextOptions: ContextOptions())
        }
        catch {
            XCTFail()
        }
        
    }
    
    func testConvertOrFailWithFormatRegex() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        
        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        
        let styles = Styles(base: bstyle)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", inputStyles: styles, placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container!.create(input: collectInput, options: options)
        cardNumber.actualValue = "4111-1111-1111-1111"

        let revealInput = RevealElementInput(token: "abc", inputStyles: styles, label: "reveal", altText: "reveal")
        let revealElement: Label? = revealContainer?.create(input: revealInput, options: RevealElementOptions(formatRegex: "..$"))
        
        
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
        
        let detokenizedValues = [revealElement!.getID(): "value"]
        
        do {
            let result = try ConversionHelpers.convertOrFail(requestBody, contextOptions: ContextOptions(), detokenizedValues: detokenizedValues)
            XCTAssertEqual((result!["resource"] as! [String: Any])["card_number"] as! String, "4111-1111-1111-1111")
            XCTAssertEqual((result!["resource"] as! [String: Any])["reveal"] as! String, "ue")
        }
        catch {
            XCTFail()
        }
        
    }
    
    
    func testParseAndConvertResponseWithFormatRegex() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        
        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        
        let styles = Styles(base: bstyle)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", inputStyles: styles, placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container!.create(input: collectInput, options: options)
        cardNumber.textField.secureText = "4111-1111-1111-1111"
        
        let revealInput = RevealElementInput(token: "abc", inputStyles: styles, label: "reveal", altText: "reveal")
        // with format regex for first two chars
        let revealElement: Label? = revealContainer?.create(input: revealInput, options: RevealElementOptions(formatRegex: "^.."))
        
        
        let responseBody: [String: Any] = [
            "resource": [
                "card_number": cardNumber,
                "nestedFields": [
                    "reveal": revealElement!
                ]
            ],
            "expirationDate": "12/22"
        ]
        
        let response: [String: Any] = [
            "resource": [
                "card_number": "cardNumber",
                "nestedFields": [
                    "card_number": "4111-1111-1111-1111",
                    "reveal": "abcd"
                ]
            ],
            "expirationDate": "12/22"
        ]
        
        
        do {
            let convertedResponse = try RequestHelpers.parseActualResponseAndUpdateElements(response: response, responseBody: responseBody, contextOptions: ContextOptions())
            waitForUIUpdates()
            
            XCTAssertEqual(convertedResponse["expirationDate"] as! String, "12/22")
            XCTAssertNil((convertedResponse["resource"] as! [String: Any])["card_number"])
            XCTAssertNil((convertedResponse["resource"] as! [String: Any])["reveal"])
             XCTAssertEqual(cardNumber.getValue(), "cardNumber")
             XCTAssertEqual(revealElement?.getValue(), "ab")
            
        } catch {
            XCTFail()
        }
    }
    
    func testConvertOrFailWithReplaceText() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        
        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        
        let styles = Styles(base: bstyle)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", inputStyles: styles, placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container!.create(input: collectInput, options: options)
        cardNumber.actualValue = "4111-1111-1111-1111"

        let revealInput = RevealElementInput(token: "abc", inputStyles: styles, label: "reveal", altText: "reveal")
        let revealElement: Label? = revealContainer?.create(input: revealInput, options: RevealElementOptions(formatRegex: "^([0-9])$", replaceText: "0$1"))
        
        
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
        
        let detokenizedValues = [revealElement!.getID(): "1"]
        
        do {
            let result = try ConversionHelpers.convertOrFail(requestBody, contextOptions: ContextOptions(), detokenizedValues: detokenizedValues)
            XCTAssertEqual((result!["resource"] as! [String: Any])["card_number"] as! String, "4111-1111-1111-1111")
            XCTAssertEqual((result!["resource"] as! [String: Any])["reveal"] as! String, "01")
        }
        catch {
            XCTFail()
        }
        
    }
    
    func testParseAndConvertResponseWithReplaceText() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)
        
        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        
        let styles = Styles(base: bstyle)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", inputStyles: styles, placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container!.create(input: collectInput, options: options)
        cardNumber.textField.secureText = "4111-1111-1111-1111"
        
        let revealInput = RevealElementInput(token: "abc", inputStyles: styles, label: "reveal", altText: "reveal")
        // with format regex for month double digit
        let revealElement: Label? = revealContainer?.create(input: revealInput, options: RevealElementOptions(formatRegex: "^([0-9])$", replaceText: "0$1"))
        
        
        let responseBody: [String: Any] = [
            "resource": [
                "card_number": cardNumber,
                "nestedFields": [
                    "month": revealElement!
                ]
            ],
            "expirationDate": "12/22"
        ]
        
        let response: [String: Any] = [
            "resource": [
                "card_number": "cardNumber",
                "nestedFields": [
                    "card_number": "4111-1111-1111-1111",
                    "month": "2"
                ]
            ],
            "expirationDate": "12/22"
        ]
        
        
        do {
            let convertedResponse = try RequestHelpers.parseActualResponseAndUpdateElements(response: response, responseBody: responseBody, contextOptions: ContextOptions())
            waitForUIUpdates()
            
            XCTAssertEqual(convertedResponse["expirationDate"] as! String, "12/22")
            XCTAssertNil((convertedResponse["resource"] as! [String: Any])["card_number"])
            XCTAssertNil((convertedResponse["resource"] as! [String: Any])["reveal"])
             XCTAssertEqual(cardNumber.getValue(), "cardNumber")
             XCTAssertEqual(revealElement?.getValue(), "02")
            
        } catch {
            XCTFail()
        }
    }
    
    func testGetFormatRegexIdsMap() {
        
        let window = UIWindow()

        let collectContainer = self.skyflow?.container(type: Skyflow.ContainerType.COLLECT, options: nil)

        let revealContainer = self.skyflow?.container(type: Skyflow.ContainerType.REVEAL, options: nil)

        let cardNumberInput = CollectElementInput(table: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)

        let cardNumberElement = collectContainer?.create(input: cardNumberInput)

        cardNumberElement?.actualValue = ProcessInfo.processInfo.environment["TEST_CARD_NUMBER"]!

        window.addSubview(cardNumberElement!)

        
        let monthInput = RevealElementInput(token: "month", inputStyles: Styles(), label: "month", altText: "Month")

        let monthElement = revealContainer?.create(input: monthInput, options: RevealElementOptions(formatRegex: "^([0-9])$", replaceText: "0$1"))
        
        let yearInput = RevealElementInput(token: "year", inputStyles: Styles(), label: "year", altText: "Year")

        let yearElement = revealContainer?.create(input: yearInput, options: RevealElementOptions(formatRegex: "..$"))

        let newElement = revealContainer?.create(input: yearInput, options: RevealElementOptions(formatRegex: "..$"))

        window.addSubview(monthElement!)
        window.addSubview(yearElement!)
        window.addSubview(newElement!)
        
        let requestBody = [
            "one": monthElement,
            "two": cardNumberElement,
            "nested": [
                "year": yearElement
            ]
        ] as [String : Any]
        let pathParams = ["new": newElement] as [String: Any]
        
        
        let connectionConfig = ConnectionConfig(connectionURL: "", method: .POST, pathParams: pathParams, requestBody: requestBody)
        do {
            let res = try connectionConfig.getLabelsToFormatInRequest(contextOptions: ContextOptions())
            XCTAssertEqual(res.count, 3)
        } catch {
            XCTFail()
        }
    }
    
    func testConvert() {
        let window = UIWindow()

        let collectContainer = self.skyflow?.container(type: Skyflow.ContainerType.COLLECT, options: nil)

        let revealContainer = self.skyflow?.container(type: Skyflow.ContainerType.REVEAL, options: nil)

        let cardNumberInput = CollectElementInput(table: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)

        let cardNumberElement = collectContainer?.create(input: cardNumberInput)

        cardNumberElement?.actualValue = ProcessInfo.processInfo.environment["TEST_CARD_NUMBER"]!

        window.addSubview(cardNumberElement!)

        
        let monthInput = RevealElementInput(token: "month", inputStyles: Styles(), label: "month", altText: "Month")

        let monthElement = revealContainer?.create(input: monthInput, options: RevealElementOptions(formatRegex: "^([0-9])$", replaceText: "0$1"))
        
        let yearInput = RevealElementInput(token: "year", inputStyles: Styles(), label: "year", altText: "Year")

        let yearElement = revealContainer?.create(input: yearInput, options: RevealElementOptions(formatRegex: "..$"))

        let newElement = revealContainer?.create(input: yearInput, options: RevealElementOptions(formatRegex: "..$"))

        window.addSubview(monthElement!)
        window.addSubview(yearElement!)
        window.addSubview(newElement!)
        
        let requestBody = [
            "one": monthElement as Any,
            "two": cardNumberElement as Any,
            "nested": [
                "year": yearElement
            ]
        ] as [String : Any]
        let pathParams = ["new": newElement as Any] as [String: Any]
        
        
        let connectionConfig = ConnectionConfig(connectionURL: "", method: .POST, pathParams: pathParams, requestBody: requestBody)
        
        do {
            let converted = try connectionConfig.convert(contextOptions: ContextOptions())
            XCTAssertEqual(converted.connectionURL, "")
            XCTAssertEqual(converted.requestBody!["nested"] as! [String: String], ["year": "year"])
            XCTAssertEqual(converted.requestBody!["one"] as! String, "month")
            XCTAssertEqual(converted.requestBody!["two"] as! String, ProcessInfo.processInfo.environment["TEST_CARD_NUMBER"]!)
            XCTAssertEqual(converted.pathParams!["new"] as! String, "year")
        } catch {
            XCTFail(error.localizedDescription)
        }
        
    }
    
    func testConvertWithDetokenize() {
        let window = UIWindow()

        let collectContainer = self.skyflow?.container(type: Skyflow.ContainerType.COLLECT, options: nil)

        let revealContainer = self.skyflow?.container(type: Skyflow.ContainerType.REVEAL, options: nil)

        let cardNumberInput = CollectElementInput(table: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)

        let cardNumberElement = collectContainer?.create(input: cardNumberInput)

        cardNumberElement?.actualValue = ProcessInfo.processInfo.environment["TEST_CARD_NUMBER"]!

        window.addSubview(cardNumberElement!)

        
        let monthInput = RevealElementInput(token: "month", inputStyles: Styles(), label: "month", altText: "Month")

        let monthElement = revealContainer?.create(input: monthInput, options: RevealElementOptions(formatRegex: "^([0-9])$", replaceText: "0$1"))
        
        let yearInput = RevealElementInput(token: "year", inputStyles: Styles(), label: "year", altText: "Year")

        let yearElement = revealContainer?.create(input: yearInput, options: RevealElementOptions(formatRegex: "..$"))

        let newElement = revealContainer?.create(input: yearInput, options: RevealElementOptions(formatRegex: "..$"))

        window.addSubview(monthElement!)
        window.addSubview(yearElement!)
        window.addSubview(newElement!)
        
        let requestBody = [
            "one": monthElement,
            "two": cardNumberElement,
            "nested": [
                "year": yearElement
            ]
        ] as [String : Any]
        let pathParams = ["new": newElement] as [String: Any]
        
        
        let connectionConfig = ConnectionConfig(connectionURL: "", method: .POST, pathParams: pathParams, requestBody: requestBody)
        
        do {
            let converted = try connectionConfig.convert(detokenizedValues: [monthElement!.getID(): "ok"], contextOptions: ContextOptions())
            
            XCTAssertEqual(converted.connectionURL, "")
            XCTAssertEqual(converted.requestBody!["nested"] as! [String: String], ["year": "year"])
            XCTAssertEqual(converted.requestBody!["one"] as! String, "ok")
            XCTAssertEqual(converted.requestBody!["two"] as! String, ProcessInfo.processInfo.environment["TEST_CARD_NUMBER"]!)
            XCTAssertEqual(converted.pathParams!["new"] as! String, "year")
        } catch {
            XCTFail(error.localizedDescription)
        }
        
    }

}
