import XCTest
@testable import Skyflow

final class skyflow_iOS_collectTests: XCTestCase {
    var skyflow: Client!

    override func setUp() {
        self.skyflow = Skyflow.initialize(
            Configuration(vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!,
                          vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!,
                          tokenProvider: DemoTokenProvider())
        )
    }

    override func tearDown() {
        skyflow = nil
    }

    func testPureInsert() {
        let records: [[String: Any]] = [
            ["table": "persons",
             "fields":
                ["cvv": "123",
                 "card_expiration": "1221",
                 "card_number": "1232132132311231",
                 "name": ["first_name": "Bob"]
                ]
            ],
            ["table": "persons",
             "fields":
                ["cvv": "123",
                 "card_expiration": "1221",
                 "card_number": "1232132132311231",
                 "name": ["first_name": "Bobb"]
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
                XCTAssertNotNil(((firstEntry?["fields"] as? [String: Any])?["name"] as? [String: Any])?["first_name"])
    }

    func testInvalidVault() {
        let skyflow = Client(Configuration(vaultID: "ff", vaultURL: "https://sb.area51.vault.skyflowapis.dev", tokenProvider: DemoTokenProvider()))

        let records: [[String: Any]] = [
            ["table": "persons",
             "fields":
                ["cvv": "123",
                 "cardExpiration": "1221",
                 "cardNumber": "1232132132311231",
                 "name": ["first_name": "Bob"]
                ]
            ],
            ["table": "persons",
             "fields":
                ["cvv": "123",
                 "cardExpiration": "1221",
                 "cardNumber": "1232132132311231",
                 "name": ["first_name": "Bobb"]
                ]
            ]
        ]
        let expectation = XCTestExpectation(description: "Pure insert call")

        let callback = DemoAPICallback(expectation: expectation)
        skyflow.insert(records: ["records": records], options: InsertOptions(tokens: true), callback: callback)

        wait(for: [expectation], timeout: 10.0)

        let data = callback.receivedResponse
        let message = data

        XCTAssertTrue(message.contains("document does not exist"))
    }

    func testCreateSkyflowElement() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: ContainerOptions())

        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)

        let styles = Styles(base: bstyle)

        let options = CollectElementOptions(required: false)

        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", inputStyles: styles, placeholder: "card number", type: .CARD_NUMBER)

        let cardNumber = container?.create(input: collectInput, options: options)

        cardNumber?.actualValue = "4111 1111 1111 1111"

        XCTAssertEqual(bstyle.borderColor, UIColor.blue)
        XCTAssertEqual(cardNumber?.getValue(), "4111 1111 1111 1111")
    }

    func testValidValueSkyflowElement() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)

        let options = CollectElementOptions(required: false)

        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER)

        let cardNumber = container?.create(input: collectInput, options: options)

        cardNumber?.actualValue = "4111 1111 1111 1111"

        let state = cardNumber?.getState()

        XCTAssertTrue(state!["isValid"] as! Bool)
    }

    // Revisit
    func testInvalidValueSkyflowElement() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)

        let options = CollectElementOptions(required: false)

        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER)

        let cardNumber = container?.create(input: collectInput, options: options)

        cardNumber?.textField.secureText = "411"

        let state = cardNumber?.getState()
        print("state", state)

        XCTAssertFalse(state!["isValid"] as! Bool)
    }

    func testCheckElementsArray() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)

        let options = CollectElementOptions(required: false)

        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER)

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

        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER)

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

        let collectInput1 = CollectElementInput(table: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)

        let cardNumber = container?.create(input: collectInput1, options: options)

        cardNumber?.actualValue = "4111 1111 1111 1111"

        window.addSubview(cardNumber!)

        let collectInput2 = CollectElementInput(table: "persons", column: "cvv", placeholder: "cvv", type: .CVV)

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
        //        XCTAssertNotNil((firstEntry?["fields"] as? [String: Any])?["skyflow_id"])
    }

    func testContainerInsertWithAdditionalFields() {
        let window = UIWindow()

        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)

        let records: [[String: Any]] = [
            ["table": "persons",
             "fields":
                [
                    "name": ["first_name": "Bob"]
                ]
            ]
        ]

        let options = CollectElementOptions(required: false)

        let collectInput1 = CollectElementInput(table: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)

        let cardNumber = container?.create(input: collectInput1, options: options)

        cardNumber?.actualValue = "4111 1111 1111 1111"

        window.addSubview(cardNumber!)

        let collectInput2 = CollectElementInput(table: "persons", column: "cvv", placeholder: "cvv", type: .CVV)

        let cvv = container?.create(input: collectInput2, options: options)

        cvv?.actualValue = "211"
        window.addSubview(cvv!)

        let collectInput3 = CollectElementInput(table: "persons", column: "card_expiration", placeholder: "card expiration", type: .EXPIRATION_DATE)

        let cardExpiration = container?.create(input: collectInput3, options: options)

        cardExpiration?.actualValue = "1222"
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
        //        XCTAssertNotNil((firstEntry?["fields"] as? [String: Any])?["skyflow_id"])
    }

    func testContainerInsertInvalidInput() {
        let window = UIWindow()

        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)

        let options = CollectElementOptions(required: false)

        let collectInput1 = CollectElementInput(table: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)

        let cardNumber = container?.create(input: collectInput1, options: options)

        cardNumber?.actualValue = "411"

        window.addSubview(cardNumber!)

        let expectation = XCTestExpectation(description: "Container insert call - All Invalid")

        let callback = DemoAPICallback(expectation: expectation)

        container?.collect(callback: callback)

        wait(for: [expectation], timeout: 10.0)

        XCTAssertEqual(callback.receivedResponse, "Invalid Value 411 as per Regex in Field card_number")
    }
    
    func testContainerInsertInvalidInputUIEdit() {
        let window = UIWindow()

        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)

        let options = CollectElementOptions(required: false)

        let collectInput1 = CollectElementInput(table: "persons", column: "card_number", label: "Card Number", placeholder: "card number", type: .CARD_NUMBER)

        let cardNumber = container?.create(input: collectInput1, options: options)

        cardNumber?.textField.secureText = "411"
        
        cardNumber?.textFieldDidEndEditing(cardNumber!.textField)

        window.addSubview(cardNumber!)
        
        let collectInput2 = CollectElementInput(table: "persons", column: "cvv", placeholder: "cvv", type: .CVV)

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

        let collectInput1 = CollectElementInput(table: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)

        let cardNumber = container?.create(input: collectInput1, options: options)

        cardNumber?.actualValue = "4111 1111 1111 1111"

        window.addSubview(cardNumber!)

        let collectInput2 = CollectElementInput(table: "persons", column: "cvv", placeholder: "cvv", type: .CVV)

        let cvv = container?.create(input: collectInput2, options: options)

        cvv?.actualValue = "2"

        window.addSubview(cvv!)

        let expectation = XCTestExpectation(description: "Container insert call - Mixed Invalid")

        let callback = DemoAPICallback(expectation: expectation)

        container?.collect(callback: callback)

        wait(for: [expectation], timeout: 10.0)

        XCTAssertEqual(callback.receivedResponse, "Invalid Value 2 as per Regex in Field cvv")
    }

    func testContainerInsertIsRequiredAndEmpty() {
        let window = UIWindow()

        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)

        let options = CollectElementOptions(required: true)

        let collectInput = CollectElementInput(table: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)

        let cardNumber = container?.create(input: collectInput, options: options)

        window.addSubview(cardNumber!)

        let expectation = XCTestExpectation(description: "Container insert call - isRequiredAndEmpty")

        let callback = DemoAPICallback(expectation: expectation)

        container?.collect(callback: callback)

        wait(for: [expectation], timeout: 10.0)

        XCTAssertEqual(callback.receivedResponse, "card_number is empty\n")
    }

    // Revisit
    func testContainerInsertIsRequiredAndNotEmpty() {
        let window = UIWindow()

        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)

        let options = CollectElementOptions(required: true)

        let collectInput = CollectElementInput(table: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)

        let cardNumber = container?.create(input: collectInput, options: options)

        cardNumber?.actualValue = "4111 1111 1111 1111"
        cardNumber?.textField.secureText = "4111 1111 1111 1111"

        window.addSubview(cardNumber!)

        let expectation = XCTestExpectation(description: "Container insert call - isRequiredAndNotEmpty")

        let callback = DemoAPICallback(expectation: expectation)

        container?.collect(callback: callback)

        wait(for: [expectation], timeout: 10.0)

        if callback.receivedResponse != "" {
            let responseData = Data(callback.receivedResponse.utf8)
            let jsonData = try! JSONSerialization.jsonObject(with: responseData, options: []) as! [String: Any]
            let responseEntries = jsonData["records"] as! [Any]
            let count = responseEntries.count
            let firstEntry = responseEntries[0] as? [String: Any]

            XCTAssertEqual(count, 1)
            XCTAssertNotNil(firstEntry?["table"])
            XCTAssertNotNil(firstEntry?["fields"])
            XCTAssertNotNil((firstEntry?["fields"] as? [String: Any])?["card_number"])
            //            XCTAssertNotNil((firstEntry?["fields"] as? [String: Any])?["skyflow_id"])
        }
    }

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
            ["table": "persons",
             "fields":
                ["cvv": "123",
                 "card_expiration": "1221",
                 "card_number": "1232132132311231",
                 "name": ["first_name": "Bob"]
                ]
            ],
            ["table": "persons",
             "fields":
                ["cvv": "123",
                 "card_expiration": "1221",
                 "card_number": "1232132132311231",
                 "name": ["first_name": "Bobb"]
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
        let card = CardType.forCardNumber(cardNumber: "4111")
        XCTAssertEqual(card.defaultName, "Visa")
    }
    
    func testCardNumberIcon() {
        let window = UIWindow()

        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)

        let options = CollectElementOptions(required: false)

        let collectInput1 = CollectElementInput(table: "persons", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)

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
        ("testContainerInsertIsRequiredAndNotEmpty", testContainerInsertIsRequiredAndNotEmpty)
    ]
}
