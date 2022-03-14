import XCTest
@testable import Skyflow

// swiftlint:disable:next type_body_length
final class skyflow_iOS_collectTests: XCTestCase {
    var skyflow: Client!
    
    override func setUp() {
        self.skyflow = Skyflow.initialize(
            Configuration(vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!,
                          vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!,
                          tokenProvider: DemoTokenProvider(),
                          options: Options(logLevel: .DEBUG, env: .DEV))
        )
    }
    
    override func tearDown() {
        skyflow = nil
    }
    
    func testPureInsert() {
        let records: [[String: Any]] = [
            ["table": "cards",
             "fields":
                ["cvv": "123",
                 "expiry_date": "1221",
                 "card_number": "1232132132311231",
                 "fullname": "Bob"
                ]
            ],
            ["table": "cards",
             "fields":
                ["cvv": "123",
                 "expiry_date": "1221",
                 "card_number": "1232132132311231",
                 "fullname": "Bobb"
                ]
            ]
        ]
        let expectation = XCTestExpectation(description: "Pure insert call")

        let callback = DemoAPICallback(expectation: expectation)
        skyflow.insert(records: ["records": records], options: InsertOptions(tokens: true), callback: callback)

        wait(for: [expectation], timeout: 10.0)

        let responseData = Data(callback.receivedResponse.utf8)
        let jsonData = try! JSONSerialization.jsonObject(with: responseData, options: []) as! [String: Any]
        let responseEntries = jsonData["records"] as! [Any]
        let count = responseEntries.count
        let firstEntry = responseEntries[0] as? [String: Any]
        let secondEntry = responseEntries[1] as? [String: Any]

        XCTAssertEqual(count, 2)
        XCTAssertNotNil(firstEntry?["table"])
        XCTAssertNotNil(firstEntry?["fields"])
        XCTAssertNotNil(secondEntry?["table"])
        XCTAssertNotNil(secondEntry?["fields"])
        XCTAssertNotNil((firstEntry?["fields"] as? [String: Any])?["card_number"])
        XCTAssertNotNil((firstEntry?["fields"] as? [String: Any])?["skyflow_id"])
        XCTAssertNotNil(((firstEntry?["fields"] as? [String: Any])?["fullname"]))
    }
    
    func testInvalidVault() {
        let skyflow = Client(Configuration(vaultID: "invalid-id", vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!, tokenProvider: DemoTokenProvider()))
        
        let records: [[String: Any]] = [
            ["table": "cards",
             "fields":
                ["cvv": "123",
                 "cardExpiration": "1221",
                 "cardNumber": "1232132132311231",
                 "fullname": "Bobb"
                ]
            ],
            ["table": "cards",
             "fields":
                ["cvv": "123",
                 "cardExpiration": "1221",
                 "cardNumber": "1232132132311231",
                 "fullname": "Bobb"
                ]
            ]
        ]
        let expectation = XCTestExpectation(description: "Pure insert call")
        
        let callback = DemoAPICallback(expectation: expectation)
        skyflow.insert(records: ["records": records], options: InsertOptions(tokens: true), callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        
        let data = callback.receivedResponse
        let message = data

        XCTAssertTrue(message.contains(" not found"))
    }
    
    func testCreateSkyflowElement() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: ContainerOptions())
        
        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        
        let styles = Styles(base: bstyle)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "cards", column: "cardNumber", inputStyles: styles, placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput, options: options)
        
        cardNumber?.actualValue = "4111 1111 1111 1111"
        
        XCTAssertEqual(bstyle.borderColor, UIColor.blue)
        XCTAssertEqual(cardNumber?.getValue(), "4111 1111 1111 1111")
    }
    
    func testValidValueSkyflowElement() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "cards", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput, options: options)
        
        cardNumber?.actualValue = "4111 1111 1111 1111"
        
        let state = cardNumber?.getState()
        
        XCTAssertTrue(state!["isValid"] as! Bool)
    }
    
    // Revisit
    func testInvalidValueSkyflowElement() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "cards", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput, options: options)
        
        cardNumber?.textField.secureText = "411"
        cardNumber?.updateActualValue()
        
        let state = cardNumber?.getState()
        
        XCTAssertFalse(state!["isValid"] as! Bool)
    }
    
    func testCheckElementsArray() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "cards", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER)
        
        _ = container?.create(input: collectInput, options: options)
        
        XCTAssertEqual(container?.elements.count, 1)
        XCTAssertTrue(container?.elements[0].fieldType == ElementType.CARD_NUMBER)
    }
    
    func testListeners() {
        let window = UIWindow()
        var onReadyCalled = false
        var onFocusCalled = false
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "cards", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER)
        
        let collectElement = container?.create(input: collectInput, options: options)
        
        
        collectElement?.on(eventName: Skyflow.EventName.CHANGE) { state in
            print("state", state)
        }
        collectElement?.on(eventName: Skyflow.EventName.BLUR) { state in
            print("state", state)
        }
        collectElement?.on(eventName: Skyflow.EventName.FOCUS) { state in
            print("state", state)
        }
        collectElement?.on(eventName: Skyflow.EventName.READY) { _ in
            onReadyCalled = true
        }
        sleep(1)
        window.addSubview(collectElement!)
        collectElement?.textField.text = "123"
        UIAccessibility.post(notification: .screenChanged, argument: collectElement)
        XCTAssertTrue(onReadyCalled)
    }
    
    func testContainerInsert() {
        let window = UIWindow()

        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)

        let options = CollectElementOptions(required: false)
        let collectInput1 = CollectElementInput(table: "cards", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)

        let cardNumber = container?.create(input: collectInput1, options: options)

        cardNumber?.actualValue = "4111 1111 1111 1111"

        window.addSubview(cardNumber!)

        let collectInput2 = CollectElementInput(table: "cards", column: "cvv", placeholder: "cvv", type: .CVV)

        let cvv = container?.create(input: collectInput2, options: options)

        cvv?.actualValue = "211"
        window.addSubview(cvv!)

        let expectation = XCTestExpectation(description: "Container insert call - All valid")

        let callback = DemoAPICallback(expectation: expectation)

        container?.collect(callback: callback)

        wait(for: [expectation], timeout: 10.0)

        let responseData = Data(callback.receivedResponse.utf8)
        let jsonData = try! JSONSerialization.jsonObject(with: responseData, options: []) as! [String: Any]
        let responseEntries = jsonData["records"] as! [Any]
        let count = responseEntries.count
        let firstEntry = responseEntries[0] as? [String: Any]

        XCTAssertEqual(count, 1)
        XCTAssertNotNil(firstEntry?["table"])
        XCTAssertNotNil(firstEntry?["fields"])
        XCTAssertNotNil((firstEntry?["fields"] as? [String: Any])?["card_number"])
        XCTAssertNotNil((firstEntry?["fields"] as? [String: Any])?["skyflow_id"])
    }
    
    func testContainerInsertWithAdditionalFields() {
        let window = UIWindow()

        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)

        let records: [[String: Any]] = [
            ["table": "cards",
             "fields":
                [
                    "fullname": "Bob"
                ]
            ]
        ]

        let options = CollectElementOptions(required: false)

        let collectInput1 = CollectElementInput(table: "cards", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)

        let cardNumber = container?.create(input: collectInput1, options: options)

        cardNumber?.actualValue = "4111 1111 1111 1111"

        window.addSubview(cardNumber!)

        let collectInput2 = CollectElementInput(table: "cards", column: "cvv", placeholder: "cvv", type: .CVV)

        let cvv = container?.create(input: collectInput2, options: options)

        cvv?.actualValue = "211"
        window.addSubview(cvv!)

        let collectInput3 = CollectElementInput(table: "cards", column: "expiry_date", placeholder: "card expiration", type: .EXPIRATION_DATE)

        let cardExpiration = container?.create(input: collectInput3, options: options)

        cardExpiration?.actualValue = "12/23"
        window.addSubview(cardExpiration!)

        let expectation = XCTestExpectation(description: "Container insert call - All valid")

        let callback = DemoAPICallback(expectation: expectation)

        container?.collect(callback: callback, options: CollectOptions(tokens: true, additionalFields: ["records": records]))

        wait(for: [expectation], timeout: 10.0)

        let responseData = Data(callback.receivedResponse.utf8)
        let jsonData = try! JSONSerialization.jsonObject(with: responseData, options: []) as! [String: Any]
        let responseEntries = jsonData["records"] as! [Any]
        let count = responseEntries.count
        let firstEntry = responseEntries[0] as? [String: Any]

        XCTAssertEqual(count, 1)
        XCTAssertNotNil(firstEntry?["table"])
        XCTAssertNotNil(firstEntry?["fields"])
        XCTAssertNotNil((firstEntry?["fields"] as? [String: Any])?["card_number"])
        XCTAssertNotNil((firstEntry?["fields"] as? [String: Any])?["skyflow_id"])
    }
    
    func testContainerInsertInvalidInput() {
        let window = UIWindow()
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput1 = CollectElementInput(table: "cards", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput1, options: options)
        
        cardNumber?.actualValue = "411"
        
        window.addSubview(cardNumber!)
        
        let expectation = XCTestExpectation(description: "Container insert call - All Invalid")
        
        let callback = DemoAPICallback(expectation: expectation)
        
        container?.collect(callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        
         XCTAssertEqual(callback.receivedResponse, "for card_number INVALID_CARD_NUMBER\n")
    }
    
    func testContainerInsertInvalidInputUIEdit() {
        let window = UIWindow()
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput1 = CollectElementInput(table: "cards", column: "card_number", label: "Card Number", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput1, options: options)
        
        cardNumber?.textField.secureText = "411"
        
        cardNumber?.textFieldDidEndEditing(cardNumber!.textField)
        
        window.addSubview(cardNumber!)
        
        let collectInput2 = CollectElementInput(table: "cards", column: "cvv", placeholder: "cvv", type: .CVV)
        
        let cvv = container?.create(input: collectInput2, options: options)
        
        cvv?.textField.secureText = "123455"
        window.addSubview(cvv!)
        
        cvv?.textFieldDidEndEditing(cvv!.textField)
        
        let expectation = XCTestExpectation(description: "Container insert call - All Invalid")
        
        let callback = DemoAPICallback(expectation: expectation)
        
        container?.collect(callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        
        XCTAssertEqual(cardNumber!.errorMessage.alpha, 1.0)
        XCTAssertEqual(cardNumber!.errorMessage.text, "Invalid Card Number")
        XCTAssertEqual(cvv!.errorMessage.alpha, 1.0)
        XCTAssertEqual(cvv!.errorMessage.text, "Invalid element")
    }
    
    func testContainerInsertMixedInvalidInput() {
        let window = UIWindow()
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput1 = CollectElementInput(table: "cards", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput1, options: options)
        
        cardNumber?.actualValue = "4111 1111 1111 1111"
        
        window.addSubview(cardNumber!)
        
        let collectInput2 = CollectElementInput(table: "cards", column: "cvv", placeholder: "cvv", type: .CVV)
        
        let cvv = container?.create(input: collectInput2, options: options)
        
        cvv?.actualValue = "2"
        
        window.addSubview(cvv!)
        
        let expectation = XCTestExpectation(description: "Container insert call - Mixed Invalid")
        
        let callback = DemoAPICallback(expectation: expectation)
        
        container?.collect(callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        
        // XCTAssertEqual(callback.receivedResponse, "Interface: collect container - Invalid Value 2 as per Regex in Field cvv")
        XCTAssertEqual(callback.receivedResponse, "for cvv INVALID_LENGTH\n")
    }
    
    func testContainerInsertIsRequiredAndEmpty() {
        let window = UIWindow()
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: true)
        
        let collectInput = CollectElementInput(table: "cards", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput, options: options)
        
        window.addSubview(cardNumber!)
        
        let expectation = XCTestExpectation(description: "Container insert call - isRequiredAndEmpty")
        
        let callback = DemoAPICallback(expectation: expectation)
        
        container?.collect(callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        
        XCTAssertEqual(callback.receivedResponse, "card_number is empty\n")
    }
    
    // Revisit
//    func testContainerInsertIsRequiredAndNotEmpty() {
//        let window = UIWindow()
//
//        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
//
//        let options = CollectElementOptions(required: true)
//
//        let collectInput = CollectElementInput(table: "cards", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
//
//        let cardNumber = container?.create(input: collectInput, options: options)
//
//        cardNumber?.textField.secureText = "4111111111111111"
//        cardNumber?.textFieldDidEndEditing(cardNumber!.textField)
//
//        window.addSubview(cardNumber!)
//
//        let expectation = XCTestExpectation(description: "Container insert call - isRequiredAndNotEmpty")
//
//        let callback = DemoAPICallback(expectation: expectation)
//
//        container?.collect(callback: callback)
//
//        wait(for: [expectation], timeout: 10.0)
//
//        if callback.receivedResponse != "" {
//            let responseData = Data(callback.receivedResponse.utf8)
//            let jsonData = try! JSONSerialization.jsonObject(with: responseData, options: []) as! [String: Any]
//            let responseEntries = jsonData["records"] as! [Any]
//            let count = responseEntries.count
//            let firstEntry = responseEntries[0] as? [String: Any]
//
//            XCTAssertEqual(count, 1)
//            XCTAssertNotNil(firstEntry?["table"])
//            XCTAssertNotNil(firstEntry?["fields"])
//            XCTAssertNotNil((firstEntry?["fields"] as? [String: Any])?["card_number"])
//            XCTAssertNotNil((firstEntry?["fields"] as? [String: Any])?["skyflow_id"])
//        }
//    }

    func testCharacterSet() {
        let charset = CharacterSet.SkyflowAsciiDecimalDigits
        let skyflowCharset = CharacterSet(charactersIn: "0123456789")
        XCTAssertEqual(charset, skyflowCharset)
    }
    
    func testInsertWithInvalidToken() {
        class InvalidTokenProvider: TokenProvider {
            func getBearerToken(_ apiCallback: Callback) {
                apiCallback.onFailure(NSError(domain: "", code: 500, userInfo: [NSLocalizedDescriptionKey: "TokenProvider error"]))
            }
        }
        
        let skyflow = Client(
            Configuration(vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!,
                          vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!,
                          tokenProvider: InvalidTokenProvider()))
        
        let records: [[String: Any]] = [
            ["table": "cards",
             "fields":
                ["cvv": "123",
                 "expiry_date": "1221",
                 "card_number": "1232132132311231",
                 "fullname": "Bobb"
                ]
            ],
            ["table": "cards",
             "fields":
                ["cvv": "123",
                 "expiry_date": "1221",
                 "card_number": "1232132132311231",
                 "fullname": "Bobb"
                ]
            ]
        ]
        let expectation = XCTestExpectation(description: "Pure insert call")
        
        let callback = DemoAPICallback(expectation: expectation)
        skyflow.insert(records: ["records": records], options: InsertOptions(tokens: true), callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        
        XCTAssertEqual(callback.receivedResponse, "TokenProvider error")
    }
    
    func testForCardNumber() {
        let card = CardType.forCardNumber(cardNumber: "4111111111111111").instance
        XCTAssertEqual(card.defaultName, "Visa")
    }
    
    func testCardNumberIcon() {
        let window = UIWindow()
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput1 = CollectElementInput(table: "cards", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput1, options: options)
        
        cardNumber?.textField.secureText = "4111"
        
        cardNumber?.textFieldDidChange(cardNumber!.textField)
        window.addSubview(cardNumber!)
        
        let image = UIImage(named: "Visa-Card", in: Bundle.module, compatibleWith: nil)
        let image2 = UIImage(named: "Mastercard-Card", in: Bundle.module, compatibleWith: nil)
        let myViews = cardNumber?.textField.leftView?.subviews.filter{$0 is UIImageView}
        
        XCTAssertEqual((myViews?[0] as? UIImageView)?.image, image)
        XCTAssertNotEqual((myViews?[0] as? UIImageView)?.image, image2)
    }
    
    func testDefaultErrorPrecedenceOnCollectFailure() {
        let myRegexRule = RegexMatchRule(regex: "\\d+", error: "Regex match failed")
        let myRules = ValidationSet(rules: [myRegexRule])
        
        let mycontainer = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let collectInput = CollectElementInput(table: "cards", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER, validations: myRules)
        let textField = mycontainer?.create(input: collectInput)
        
        let window = UIWindow()
        window.addSubview(textField!)
        

        textField?.textField.secureText = "invalid"
        textField?.textFieldDidEndEditing(textField!.textField)
        let expectFailure = XCTestExpectation(description: "Should fail")
        let myCallback = DemoAPICallback(expectation: expectFailure)
        mycontainer?.collect(callback: myCallback)
        wait(for: [expectFailure], timeout: 10.0)
        
        XCTAssertEqual(myCallback.receivedResponse, "for cardNumber INVALID_CARD_NUMBER\n")
    }
    
    func testCustomValidationErrorOnCollectFailure() {
        let myRegexRule = RegexMatchRule(regex: "(\\d-){4}+\\d{4}", error: "Regex match failed")
        let myRules = ValidationSet(rules: [myRegexRule])
        
        let mycontainer = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let collectInput = CollectElementInput(table: "cards", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER, validations: myRules)
        let textField = mycontainer?.create(input: collectInput)
        
        let window = UIWindow()
        window.addSubview(textField!)
        

        textField?.textField.secureText = "4111-1111-1111-1111"
        textField?.textFieldDidEndEditing(textField!.textField)
        let expectFailure = XCTestExpectation(description: "Should fail")
        let myCallback = DemoAPICallback(expectation: expectFailure)
        mycontainer?.collect(callback: myCallback)
        wait(for: [expectFailure], timeout: 10.0)
        
        XCTAssertEqual(myCallback.receivedResponse, "for cardNumber Regex match failed\n")
    }
    

    func testPinElement() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let collectOptions = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "cards", column: "pin", placeholder: "pin", type: .PIN)
        
        let pinElement = container?.create(input: collectInput, options: collectOptions)
        
        pinElement?.textField.secureText = "1234"
        XCTAssertTrue((pinElement?.state.getState()["isValid"]) as! Bool)
        
        pinElement?.actualValue = "abc$%6"
        XCTAssertFalse((pinElement?.state.getState()["isValid"]) as! Bool)
        
        pinElement?.actualValue = "123"
        XCTAssertFalse((pinElement?.state.getState()["isValid"]) as! Bool)
        
        pinElement?.actualValue = "1234567890123456"
        XCTAssertFalse((pinElement?.state.getState()["isValid"]) as! Bool)
        
        pinElement?.actualValue = "123456789012"
        XCTAssertTrue((pinElement?.state.getState()["isValid"]) as! Bool)
    }
    
    func testSetErrorOnCollect() {
        let myRegexRule = RegexMatchRule(regex: "\\d+", error: "Regex match failed")
        let myRules = ValidationSet(rules: [myRegexRule])
        
        let mycontainer = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let collectInput = CollectElementInput(table: "cards", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER, validations: myRules)
        let textField = mycontainer?.create(input: collectInput)
        
        let window = UIWindow()
        window.addSubview(textField!)
        

        textField?.textField.secureText = "invalid"
        textField?.setError("triggered error")
        textField?.textFieldDidEndEditing(textField!.textField)
        let expectFailure = XCTestExpectation(description: "Should fail")
        let myCallback = DemoAPICallback(expectation: expectFailure)
        mycontainer?.collect(callback: myCallback)
        wait(for: [expectFailure], timeout: 10.0)
        
        XCTAssertEqual(myCallback.receivedResponse, "for cardNumber triggered error\n")
    }
    func testElementValueMatchRule() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let collectOptions = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "cards", column: "pin", placeholder: "pin", type: .PIN)
        
        let pinElement = container?.create(input: collectInput, options: collectOptions)
        
        var vs = ValidationSet()
        vs.add(rule: ElementValueMatchRule(element: pinElement!, error: "ELEMENT NOT MATCHING"))
        
        let collectInput2 = CollectElementInput(table: "cards", column: "", placeholder: "pin", type: .PIN, validations: vs)
        
        let confirmPinElement = container?.create(input: collectInput2, options: collectOptions)
        
        pinElement!.textField.secureText = "1234"
        pinElement!.textFieldDidEndEditing(pinElement!.textField)
        
        confirmPinElement!.textField.secureText = "1235"
        confirmPinElement!.textFieldDidEndEditing(confirmPinElement!.textField)
        
        XCTAssertFalse((confirmPinElement?.state.getState()["isValid"]) as! Bool)
        
        confirmPinElement!.textField.secureText = "1234"
        confirmPinElement!.textFieldDidEndEditing(confirmPinElement!.textField)
        
        XCTAssertTrue((confirmPinElement?.state.getState()["isValid"]) as! Bool)
    }
    
    func testCollectCreateRequestBodyWithElementValueMatchRule(){
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let collectOptions = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "cards", column: "pin", placeholder: "pin", type: .PIN)
        
        let pinElement = container?.create(input: collectInput, options: collectOptions)
        
        var vs = ValidationSet()
        vs.add(rule: ElementValueMatchRule(element: pinElement!, error: "ELEMENT NOT MATCHING"))
        
        let collectInput2 = CollectElementInput(table: "cards", column: "pin", placeholder: "pin", type: .PIN, validations: vs)
        
        let confirmPinElement = container?.create(input: collectInput2, options: collectOptions)
        
        pinElement!.textField.secureText = "1234"
        pinElement!.textFieldDidEndEditing(pinElement!.textField)
        
        confirmPinElement!.textField.secureText = "1235"
        confirmPinElement!.textFieldDidEndEditing(confirmPinElement!.textField)
        
        var elements: [TextField] = []
        
        elements.append(pinElement!)
        elements.append(confirmPinElement!)
        
        let expectSuccess = XCTestExpectation(description: "Should succeed")
        let myCallback = DemoAPICallback(expectation: expectSuccess)
        
        let records = CollectRequestBody.createRequestBody(elements: elements, callback: myCallback, contextOptions: ContextOptions())
        
        let recordElement = (records?["records"] as? [[String: Any]])?[0]
        let fields = recordElement?["fields"] as? [String: Any]
        let pin = fields?["pin"] as? String
        
        XCTAssertEqual(pin, "1234")
    }
    
    func testCollectElementSetValueAndClearValue(){
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let collectInput = CollectElementInput(table: "cards", column: "cvv", placeholder: "cvv", type: .CVV)
        
        let cvvElement = container?.create(input: collectInput)
        
        XCTAssertEqual(cvvElement?.actualValue, "")
        XCTAssertEqual(cvvElement?.textField.secureText, "")
        
        cvvElement?.setValue(value: "123")
        
        XCTAssertEqual(cvvElement?.actualValue, "123")
        XCTAssertEqual(cvvElement?.textField.secureText, "123")
        
        cvvElement?.clearValue()
        
        XCTAssertEqual(cvvElement?.actualValue, "")
        XCTAssertEqual(cvvElement?.textField.secureText, "")
    }
    
    static var allTests = [
        ("testPureInsert", testPureInsert),
        ("testInvalidVault", testInvalidVault),
        ("testCreateSkyflowElement", testCreateSkyflowElement),
        ("testValidValueSkyflowElement", testValidValueSkyflowElement),
        ("testInvalidValueSkyflowElement", testInvalidValueSkyflowElement),
        ("testCheckElementsArray", testCheckElementsArray),
        ("testContainerInsert", testContainerInsert),
        ("testContainerInsertInvalidInput", testContainerInsertInvalidInput),
        ("testContainerInsertMixedInvalidInput", testContainerInsertMixedInvalidInput),
        ("testContainerInsertIsRequiredAndEmpty", testContainerInsertIsRequiredAndEmpty),
//        ("testContainerInsertIsRequiredAndNotEmpty", testContainerInsertIsRequiredAndNotEmpty)
    ]
}
