import XCTest
@testable import Skyflow

final class skyflow_iOS_collectTests: XCTestCase {
    
    var skyflow: Client!
    var records: [[String: Any]]!
    
    override func setUp() {
        self.skyflow = Client(Configuration(vaultID: "b359c43f1b844ff4bea0f098d2c09193", vaultURL: "https://sb1.area51.vault.skyflowapis.tech/", tokenProvider: DemoTokenProvider()))
        self.records = [
            ["table": "cards",
             "fields":
                ["cvv": "123",
                 "expiry_date":"1221",
                 "card_number": "1232132132311231",
                 "fullname": "Bob"
                ]
            ],
            ["table": "cards",
             "fields":
                ["cvv": "123",
                 "expiry_date":"1221",
                 "card_number": "1232132132311231",
                 "fullname": "Bobb"
                ]
            ]
            ]
        
    }
    
    override func tearDown() {
        skyflow = nil
    }
    
    func testPureInsert() {
        
        let expectation = XCTestExpectation(description: "Pure insert call")
        
        let callback = DemoAPICallback(expectation: expectation)
        skyflow.insert(records: ["records": records!],options: InsertOptions(tokens: true), callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        print(callback.receivedResponse.utf8)
        let responseData = Data(callback.receivedResponse.utf8)
        let jsonData = try! JSONSerialization.jsonObject(with: responseData, options: []) as! [String:Any]
        let responseEntries = jsonData["records"] as! [Any]
        let count = responseEntries.count
        let firstEntry = responseEntries[0] as? [String: Any]
        let secondEntry = responseEntries[1] as? [String: Any]

        XCTAssertEqual(count, 2)
        XCTAssertNotNil(firstEntry?["table"])
        XCTAssertNotNil(firstEntry?["fields"])
        XCTAssertNotNil(secondEntry?["table"])
        XCTAssertNotNil(secondEntry?["fields"])
        XCTAssertNotNil((firstEntry?["fields"] as? [String:Any])?["card_number"])
        XCTAssertNotNil((firstEntry?["fields"] as? [String:Any])?["expiry_date"])
        XCTAssertNotNil((firstEntry?["fields"] as? [String: Any])?["cvv"])
        XCTAssertNotNil(((firstEntry?["fields"] as? [String:Any])?["fullname"]))
    }
    
    func testInvalidVault() {
        
        let skyflow = Client(Configuration(vaultID: "ff", vaultURL: "https://sb1.area51.vault.skyflowapis.tech/", tokenProvider: DemoTokenProvider()))
        
                let expectation = XCTestExpectation(description: "Pure insert call")
        
        let callback = DemoAPICallback(expectation: expectation)
        skyflow.insert(records: ["records": records],options: InsertOptions(tokens: true), callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        
        let data = Data(callback.receivedResponse.utf8)
        print(callback.receivedResponse.utf8)
        let jsonData = try! JSONSerialization.jsonObject(with: data, options: []) as! [String:Any]
        let errorJson = jsonData["error"] as! [String: Any]
        let message = errorJson["message"] as! String
        
        XCTAssertTrue(message.contains("document does not exist"))
    }
    
    func testCreateSkyflowElement(){
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        
        let styles = Styles(base: bstyle)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", styles: styles, placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput, options: options) as? TextField
        
        cardNumber?.textField.secureText = "4111 1111 1111 1111"

        XCTAssertEqual(bstyle.borderColor, UIColor.blue)
        XCTAssertEqual(cardNumber?.getOutput(), "4111 1111 1111 1111")
    }
    
    func testValidValueSkyflowElement() {
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput, options: options) as? TextField
        
        cardNumber?.textField.secureText = "4111 1111 1111 1111"
        
        let state = cardNumber?.getState()
        
        XCTAssertTrue(state!["isValid"] as! Bool)
    }
    
    func testInvalidValueSkyflowElement() {
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput, options: options) as? TextField
        
        cardNumber?.textField.secureText = "411"
        
        let state = cardNumber?.getState()
        
        XCTAssertFalse(state!["isValid"] as! Bool)
    }
    
    func testCheckElementsArray() {
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput, options: options)
        
        XCTAssertEqual(container?.elements.count, 1)
        XCTAssertTrue(container?.elements[0].fieldType == ElementType.CARD_NUMBER)
    }
    
    func testContainerInsert() {
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput1 = CollectElementInput(table: "cards", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput1, options: options) as! TextField
        
        cardNumber.textField.secureText = "4111 1111 1111 1111"
        
        let collectInput2 = CollectElementInput(table: "cards", column: "cvv", placeholder: "cvv", type: .CVV)
        
        let cvv = container?.create(input: collectInput2, options: options) as! TextField
        
        cvv.textField.secureText = "211"
        
        let expectation = XCTestExpectation(description: "Container insert call - All valid")
        
        let callback = DemoAPICallback(expectation: expectation)
        
        container?.collect(callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        
        let responseData = Data(callback.receivedResponse.utf8)
        let jsonData = try! JSONSerialization.jsonObject(with: responseData, options: []) as! [String:Any]
        let responseEntries = jsonData["records"] as! [Any]
        let count = responseEntries.count
        let firstEntry = responseEntries[0] as? [String: Any]

        XCTAssertEqual(count, 1)
        XCTAssertNotNil(firstEntry?["table"])
        XCTAssertNotNil(firstEntry?["fields"])
        XCTAssertNotNil((firstEntry?["fields"] as? [String:Any])?["card_number"])
        XCTAssertNotNil((firstEntry?["fields"] as? [String:Any])?["cvv"])
    }
    
    func testContainerInsertInvalidInput() {
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput1 = CollectElementInput(table: "persons", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput1, options: options) as! TextField
        
        cardNumber.textField.secureText = "411"
        
        let collectInput2 = CollectElementInput(table: "persons", column: "cvv", placeholder: "cvv", type: .CVV)
        
        let cvv = container?.create(input: collectInput2, options: options) as! TextField
        
        cvv.textField.secureText = "2"
        
        let expectation = XCTestExpectation(description: "Container insert call - All Invalid")
        
        let callback = DemoAPICallback(expectation: expectation)
        
        container?.collect(callback: callback)
        
        wait(for: [expectation], timeout: 10.0)

        XCTAssertEqual(callback.receivedResponse, "for cardNumber INVALID_CARD_NUMBER\nfor cvv INVALID_LENGTH_MATCH\n")
    }
    
    func testContainerInsertMixedInvalidInput() {
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput1 = CollectElementInput(table: "persons", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput1, options: options) as! TextField
        
        cardNumber.textField.secureText = "4111 1111 1111 1111"
        
        let collectInput2 = CollectElementInput(table: "persons", column: "cvv", placeholder: "cvv", type: .CVV)
        
        let cvv = container?.create(input: collectInput2, options: options) as! TextField
        
        cvv.textField.secureText = "2"
        
        let expectation = XCTestExpectation(description: "Container insert call - Mixed Invalid")
        
        let callback = DemoAPICallback(expectation: expectation)
        
        container?.collect(callback: callback)
        
        wait(for: [expectation], timeout: 10.0)

        XCTAssertEqual(callback.receivedResponse, "for cvv INVALID_LENGTH_MATCH\n")
    }
    
    func testContainerInsertIsRequiredAndEmpty() {
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: true)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput, options: options)
        
        let expectation = XCTestExpectation(description: "Container insert call - isRequiredAndEmpty")
        
        let callback = DemoAPICallback(expectation: expectation)
        
        container?.collect(callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        
        XCTAssertEqual(callback.receivedResponse, "cardNumber is empty\n")

    }
    
    func testContainerInsertIsRequiredAndNotEmpty() {
        
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        
        let options = CollectElementOptions(required: true)
        
        let collectInput = CollectElementInput(table: "cards", column: "card_number", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput, options: options) as! TextField
        
        cardNumber.textField.secureText = "4111 1111 1111 1111"
        
        let expectation = XCTestExpectation(description: "Container insert call - isRequiredAndNotEmpty")
        
        let callback = DemoAPICallback(expectation: expectation)
        
        container?.collect(callback: callback)
        
        wait(for: [expectation], timeout: 10.0)
        
        if(callback.receivedResponse != ""){
            let responseData = Data(callback.receivedResponse.utf8)
            print(callback.receivedResponse.utf8)
            let jsonData = try! JSONSerialization.jsonObject(with: responseData, options: []) as! [String:Any]
            let responseEntries = jsonData["records"] as! [Any]
            let count = responseEntries.count
            let firstEntry = responseEntries[0] as? [String: Any]

            XCTAssertEqual(count, 1)
            XCTAssertNotNil(firstEntry?["table"])
            XCTAssertNotNil(firstEntry?["fields"])
            XCTAssertNotNil((firstEntry?["fields"] as? [String:Any])?["card_number"])
        }
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
        ("testContainerInsertIsRequiredAndNotEmpty", testContainerInsertIsRequiredAndNotEmpty),
    ]
}
