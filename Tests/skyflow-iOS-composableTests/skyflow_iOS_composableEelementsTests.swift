//
//  skyflow_iOS_composableEelementsTests.swift
//  
//
//  Created by Bharti Sagar on 31/07/23.
//

import XCTest
@testable import Skyflow

final class skyflow_iOS_composableEelementsTests: XCTestCase {
    var skyflow: Client!
    
    override func setUp() {
        self.skyflow = Skyflow.initialize(
            Configuration(
                vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!,
                vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!,
                tokenProvider: DemoTokenProvider(),
                options: Options(logLevel: .DEBUG, env: .DEV))
        )
    }
    
    override func tearDown() {
        skyflow = nil
    }
    func testContainerOptionsNil() {
        let container = skyflow.container(type: ContainerType.COMPOSABLE, options: nil)
        
        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        
        let styles = Styles(base: bstyle)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardnumber", inputStyles: styles, placeholder: "card number", type: .CARD_NUMBER)
        
        _ = container?.create(input: collectInput, options: options)
        
        do {
            _ = try container?.getComposableView()
        } catch {
            XCTAssertEqual(error.localizedDescription.description, SkyflowError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Interface: \(ContextOptions(interface: .COMPOSABLE_CONTAINER).interface.description) - \(ErrorCodes.MISSING_COMPOSABLE_CONTAINER_OPTIONS().description)" ]).localizedDescription)
        }
        XCTAssertEqual(bstyle.borderColor, UIColor.blue)
    }
    
    func testContainerOptionsEmpty() {
        let container = skyflow.container(type: ContainerType.COMPOSABLE, options: ContainerOptions())
        
        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        
        let styles = Styles(base: bstyle)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardnumber", inputStyles: styles, placeholder: "card number", type: .CARD_NUMBER)
        
        _ = container?.create(input: collectInput, options: options)
        
        do {
            _ = try container?.getComposableView()
        } catch {
            XCTAssertEqual(error.localizedDescription.description, SkyflowError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Interface: \(ContextOptions(interface: .COMPOSABLE_CONTAINER).interface.description) - \(ErrorCodes.MISMATCH_ELEMENT_COUNT_LAYOUT_SUM().description)" ]).localizedDescription)
        }
        XCTAssertEqual(bstyle.borderColor, UIColor.blue)
    }
    func testContainerOptionsLayoutIsless() {
        let container = skyflow.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [0]))
        
        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        
        let styles = Styles(base: bstyle)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardnumber", inputStyles: styles, placeholder: "card number", type: .CARD_NUMBER)
        
        _ = container?.create(input: collectInput, options: options)
        
        do {
            _ = try container?.getComposableView()
        } catch {
            XCTAssertEqual(error.localizedDescription.description, SkyflowError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Interface: \(ContextOptions(interface: .COMPOSABLE_CONTAINER).interface.description) - \(ErrorCodes.MISMATCH_ELEMENT_COUNT_LAYOUT_SUM().description)" ]).localizedDescription)
        }
        XCTAssertEqual(bstyle.borderColor, UIColor.blue)
    }
    func testContainerOptionsLayoutMismatch() {
        let container = skyflow.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [2]))
        
        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        
        let styles = Styles(base: bstyle)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardnumber", inputStyles: styles, placeholder: "card number", type: .CARD_NUMBER)
        
        _ = container?.create(input: collectInput, options: options)
        
        do {
            _ = try container?.getComposableView()
        } catch {
            XCTAssertEqual(error.localizedDescription.description, SkyflowError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Interface: \(ContextOptions(interface: .COMPOSABLE_CONTAINER).interface.description) - \(ErrorCodes.MISMATCH_ELEMENT_COUNT_LAYOUT_SUM().description)" ]).localizedDescription)
        }
        XCTAssertEqual(bstyle.borderColor, UIColor.blue)
    }
    func testContainerOptionsLayoutSuccess() {
        let container = skyflow.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))
        
        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        
        let styles = Styles(base: bstyle)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardnumber", inputStyles: styles, placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput, options: options)
        cardNumber?.actualValue = "4111 1111 1111 1111"

        do {
            _ = try container?.getComposableView()
        } catch {
            XCTFail(error.localizedDescription)
        }
        XCTAssertEqual(bstyle.borderColor, UIColor.blue)
        XCTAssertEqual(cardNumber?.getValue(), "4111 1111 1111 1111")
    }
    func testListeners() {
        let window = UIWindow()
        var onReadyCalled = false
        var onFocusCalled = false
        var onBlurCalled = false
        var onChangeCalled = false
        let container = skyflow.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardnumber", placeholder: "card number", type: .CARD_NUMBER)
        
        let collectElement = container?.create(input: collectInput, options: options)
        
        
        collectElement?.on(eventName: Skyflow.EventName.CHANGE) { state in
            print("state", state)
            onChangeCalled = true
        }
        collectElement?.on(eventName: Skyflow.EventName.BLUR) { state in
            print("state", state)
            onBlurCalled = true
            
        }
        collectElement?.on(eventName: Skyflow.EventName.FOCUS) { state in
            print("state", state)
            onFocusCalled = true
        }
        collectElement?.on(eventName: Skyflow.EventName.READY) { _ in
            onReadyCalled = true
        }
        sleep(1)
        window.addSubview(collectElement!)
        collectElement?.textField.text = "123"
        UIAccessibility.post(notification: .screenChanged, argument: collectElement)
        XCTAssertTrue(onReadyCalled)
        collectElement?.becomeFirstResponder()
        XCTAssertTrue(onFocusCalled)
        collectElement?.setValue(value: "4111 1111 1111 1111")
        XCTAssertTrue(onChangeCalled)
        collectElement?.resignFirstResponder()
        XCTAssertTrue(onBlurCalled)
    }
    func testContainerInsertInvalidInput() {
        let window = UIWindow()
        
        let container = skyflow.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))
        
        let options = CollectElementOptions(required: false)
        
        let collectInput1 = CollectElementInput(table: "persons", column: "cardnumber", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput1, options: options)
        do {
            let view  = try container?.getComposableView()
            window.addSubview(view!)
            cardNumber?.actualValue = "411"
            
            
            let expectation = XCTestExpectation(description: "Container insert call - All Invalid")
            
            let callback = DemoAPICallback(expectation: expectation)
            
            container?.collect(callback: callback)
            
            wait(for: [expectation], timeout: 10.0)
            
            XCTAssertEqual(callback.receivedResponse, """
                for cardnumber INVALID_CARD_NUMBER
                
                """)

        } catch {
            print(error)
        }
        

    }
    
    func testContainerInsertInvalidInputUIEdit() {
        let window = UIWindow()
        
        let container = skyflow.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [2]))

        let options = CollectElementOptions(required: false)
        
        let collectInput1 = CollectElementInput(table: "persons", column: "cardnumber", label: "Card Number", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput1, options: options)
        
        cardNumber?.textField.secureText = "411"
        
        cardNumber?.textFieldDidEndEditing(cardNumber!.textField)
        
        let collectInput2 = CollectElementInput(table: "persons", column: "cvv", placeholder: "cvv", type: .CVV)
        
        let cvv = container?.create(input: collectInput2, options: options)
        
        cvv?.textField.secureText = "123455"
        
        cvv?.textFieldDidEndEditing(cvv!.textField)
        do {
            let view  = try container?.getComposableView()
            window.addSubview(view!)
            
            
            let expectation = XCTestExpectation(description: "Container insert call - All Invalid")
            
            let callback = DemoAPICallback(expectation: expectation)
            
            container?.collect(callback: callback)
            
            wait(for: [expectation], timeout: 10.0)
            
            XCTAssertEqual(cardNumber!.errorMessage.alpha, 1.0)
            XCTAssertEqual(cardNumber!.errorMessage.text, "Invalid Card Number")
            XCTAssertEqual(cvv!.errorMessage.alpha, 1.0)
            XCTAssertEqual(cvv!.errorMessage.text, "Invalid element")
        } catch {
            print(error)
        }
 
    }
    func testContainerInsertIsRequiredAndEmpty() {
        let window = UIWindow()
        
        let container = skyflow.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))

        let options = CollectElementOptions(required: true)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardnumber", placeholder: "card number", type: .CARD_NUMBER)
        
        _ = container?.create(input: collectInput, options: options)
        do {
            let view = try container?.getComposableView()
            window.addSubview(view!)
            let expectation = XCTestExpectation(description: "Container insert call - isRequiredAndEmpty")
            
            let callback = DemoAPICallback(expectation: expectation)
            
            container?.collect(callback: callback)
            
            wait(for: [expectation], timeout: 10.0)
            
            XCTAssertEqual(callback.receivedResponse, "cardnumber is empty\n")
        } catch {
            print(error)
        }
        
    }
    func testDefaultErrorPrecedenceOnCollectFailure() {
        let myRegexRule = RegexMatchRule(regex: "\\d+", error: "Regex match failed")
        let myRules = ValidationSet(rules: [myRegexRule])
        
        let mycontainer = skyflow.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [2]))

        let collectInput = CollectElementInput(table: "persons", column: "cardnumber", placeholder: "card number", type: .CARD_NUMBER, validations: myRules)
        let textField = mycontainer?.create(input: collectInput)
        do {
            let view = try mycontainer?.getComposableView()
            let window = UIWindow()
            window.addSubview(view!)
            

            textField?.textField.secureText = "invalid"
            textField?.textFieldDidEndEditing(textField!.textField)
            let expectFailure = XCTestExpectation(description: "Should fail")
            let myCallback = DemoAPICallback(expectation: expectFailure)
            mycontainer?.collect(callback: myCallback)
            wait(for: [expectFailure], timeout: 10.0)
            
            XCTAssertEqual(myCallback.receivedResponse, "for cardnumber INVALID_CARD_NUMBER\n")
            
        } catch {
            print(error)
        }

    }
    func testSetErrorOnCollect() {
        let myRegexRule = RegexMatchRule(regex: "\\d+", error: "Regex match failed")
        let myRules = ValidationSet(rules: [myRegexRule])
        
        let mycontainer = skyflow.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))
        
        let collectInput = CollectElementInput(table: "persons", column: "cardnumber", placeholder: "card number", type: .CARD_NUMBER, validations: myRules)
        let textField = mycontainer?.create(input: collectInput)
        do {
            let view = try mycontainer?.getComposableView()
            let window = UIWindow()
            window.addSubview(view!)
            textField?.textField.secureText = "invalid"
            textField?.setError("triggered error")
            textField?.textFieldDidEndEditing(textField!.textField)
            
            let expectFailure = XCTestExpectation(description: "Should fail")
            let myCallback = DemoAPICallback(expectation: expectFailure)
            mycontainer?.collect(callback: myCallback)
            
            wait(for: [expectFailure], timeout: 10.0)
            XCTAssertEqual(myCallback.receivedResponse, "for cardnumber triggered error\n")
        } catch {
            print(error)
        }

       
    }
    func testElementValueMatchRule() {
        let container = skyflow.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))
        
        let collectOptions = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "persons", column: "pin", placeholder: "pin", type: .PIN)
        
        let pinElement = container?.create(input: collectInput, options: collectOptions)
        
        var vs = ValidationSet()
        vs.add(rule: ElementValueMatchRule(element: pinElement!, error: "ELEMENT NOT MATCHING"))
        
        let collectInput2 = CollectElementInput(table: "persons", column: "", placeholder: "pin", type: .PIN, validations: vs)
        
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
    func testUpdateCollectElement() {
        let container = skyflow.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))
        
        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        
        let styles = Styles(base: bstyle)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardnumber", inputStyles: styles, placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput, options: options)
        cardNumber?.actualValue = "4111 1111 1111 1111"

        do {
            let view = try container?.getComposableView()
            let window = UIWindow()
            window.addSubview(view!)
            cardNumber?.update(update: CollectElementInput(inputStyles: Styles(base: Style(borderColor: .red))))
        } catch {
            XCTFail(error.localizedDescription)
        }
        XCTAssertEqual(bstyle.borderColor, UIColor.blue)
        XCTAssertEqual(cardNumber?.getValue(), "4111 1111 1111 1111")
        XCTAssertEqual(cardNumber?.collectInput.inputStyles.base?.borderColor, .red)
        XCTAssertEqual(cardNumber?.collectInput.inputStyles.base?.cornerRadius, 20)
    }
    func testUpdateCollectElement2() {
        let container = skyflow.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))
        
        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        
        let styles = Styles(base: bstyle)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardnumber", inputStyles: styles, placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput, options: options)
        cardNumber?.actualValue = "4111 1111 1111 1111"

        do {
            let view = try container?.getComposableView()
            let window = UIWindow()
            window.addSubview(view!)
            cardNumber?.update(update: CollectElementInput(inputStyles: Styles(base: Style(borderColor: .red)), type: .CARDHOLDER_NAME))
        } catch {
            XCTFail(error.localizedDescription)
        }
        XCTAssertEqual(bstyle.borderColor, UIColor.blue)
        XCTAssertEqual(cardNumber?.getValue(), "4111 1111 1111 1111")
        XCTAssertEqual(cardNumber?.collectInput.inputStyles.base?.borderColor, .red)
        XCTAssertEqual(cardNumber?.collectInput.inputStyles.base?.cornerRadius, 20)
        XCTAssertEqual(cardNumber?.fieldType, .CARD_NUMBER)
        XCTAssertNotEqual(cardNumber?.fieldType, .CARDHOLDER_NAME)
    }
    func testAutoShiftBetweenElement() {
        let container = skyflow.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [2]))
        
        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)
        
        let styles = Styles(base: bstyle)
        
        let options = CollectElementOptions(required: false)
        
        let collectInput1 = CollectElementInput(table: "persons", column: "cardnumber",inputStyles: styles, label: "Card Number", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput1, options: options)
        let collectInput2 = CollectElementInput(table: "persons", column: "cvv", placeholder: "cvv", type: .CVV)
        
        let cvv = container?.create(input: collectInput2, options: options)
        

        do {
            let view = try container?.getComposableView()
            cardNumber?.textField.secureText = "4111111111111111"
            cardNumber?.textFieldDidEndEditing(cardNumber!.textField)
            cvv?.textField.secureText = "123455"
            cvv?.textFieldDidEndEditing(cvv!.textField)
            let window = UIWindow()
            window.addSubview(view!)
            XCTAssertEqual(bstyle.borderColor, UIColor.blue)
            XCTAssertEqual(cardNumber?.getValue(), "4111111111111111")
            XCTAssertEqual(cardNumber?.collectInput.inputStyles.base?.borderColor, .blue)
            XCTAssertEqual(cardNumber?.collectInput.inputStyles.base?.cornerRadius, 20)
            XCTAssertEqual(cardNumber?.fieldType, .CARD_NUMBER)
        } catch {
            XCTFail(error.localizedDescription)
        }

    }
    func testInsertEmptyTableNameForUpsertOption() {
        _ = skyflow.container(type: ContainerType.COMPOSABLE)
        let upsertOptions = [["column": "person"]]
        let expectation = XCTestExpectation()
        let records = [
          "records" : [[
            "table": "card1",
            "fields": [
              "person" : "abcfgdyt",
                "cvv" : "567"
            ]
          ]]
        ]
        let callback = DemoAPICallback(expectation: expectation)
        let insertOptions = Skyflow.InsertOptions(tokens: false, upsert: upsertOptions)
        self.skyflow?.insert(records: records, options: insertOptions, callback: callback)
        wait(for: [expectation], timeout: 20.0)

        XCTAssertEqual(callback.receivedResponse, ErrorCodes.MISSING_TABLE_NAME_IN_USERT_OPTION().getErrorObject(contextOptions: ContextOptions(interface: InterfaceName.INSERT)).localizedDescription)
    }
    func testCollectBadTableKeyAddionalFields() {
        let additionalFields = ["records": [["table": []]]]
        let container = skyflow.container(type: ContainerType.COMPOSABLE)
        
        let expectation = XCTestExpectation()
        let callback = DemoAPICallback(expectation: expectation)
        container?.collect(callback: callback, options: CollectOptions(tokens: true, additionalFields: additionalFields))
        
        wait(for: [expectation], timeout: 20.0)
        
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.INVALID_TABLE_NAME_TYPE().getErrorObject(contextOptions: ContextOptions(interface: InterfaceName.COMPOSABLE_CONTAINER)).localizedDescription)
    }
    func testCreateRows() {
        let elements = [1, 2]
        let numberOfRows = 2
        let expectedResult = [[1], [2, 3]]
        let container = skyflow.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1, 2]))

        var result = container?.createRows(from: elements, numberOfRows: numberOfRows)
        XCTAssertEqual(result, expectedResult)
        
        result = container?.createRows(from: [1,2,3], numberOfRows: 3)
        XCTAssertEqual(result, [[1],[2,3],[4,5,6]])

        }
    
    // Test Case 1: Test with valid input
    func testUpdateErrorMessageInLabel() {
            let errorList = ["Error 1", "Error 2", "Error 3", "Error 4", "Error 5","Error 6","Error 7", "Error 8", "Error 9"]
            let layout = [2, 3, 4]
            let label1 = UILabel()
            let label2 = UILabel()
            let label3 = UILabel()
            let labelArray = [label1, label2, label3]
            let result = [[1, 2], [3, 4, 5], [6, 7, 8, 9]]
            let expectedLabelTexts = ["Error 1Error 2", "Error 3Error 4Error 5", "Error 6Error 7Error 8Error 9"]
        let container = skyflow.container(type: ContainerType.COMPOSABLE)
        let updatedLabelArray = container?.updateErrorMessageInLabel(errorList: errorList, layout: layout, labelArray: labelArray, result: result)
            
        for (index, label) in updatedLabelArray!.enumerated() {
                XCTAssertEqual(label.text, expectedLabelTexts[index])
            }

        
        }
    
    // Test Case 2: Test with empty errorList and layout
    func testUpdateErrorMessageInLabelWithEmptyError(){
        let emptyErrorList = [String]()
        let emptyLayout = [Int]()
        let emptyLabel1 = UILabel()
        let emptyLabel2 = UILabel()
        let emptyLabelArray = [emptyLabel1, emptyLabel2]
        let emptyResult = [[Int]]()
        let container = skyflow.container(type: ContainerType.COMPOSABLE)

        let emptyUpdatedLabelArray = container?.updateErrorMessageInLabel(errorList: emptyErrorList, layout: emptyLayout, labelArray: emptyLabelArray, result: emptyResult)
        for (_, label) in emptyUpdatedLabelArray!.enumerated() {
            XCTAssertEqual(label.text, nil)
        }
    }
    func testConcatenateStringArray() {
            // Test Case 1: Test with valid input
            let inputArray = ["Hello", " ", "World", "!"]
            let startIndex = 0
            let endIndex = 3
            let expectedResult = "Hello World!"
            let container = skyflow.container(type: ContainerType.COMPOSABLE)

        let result = container?.concatenateStringArray(inputArray, from: startIndex, to: endIndex)
            XCTAssertEqual(result, expectedResult)
        }
    
    // Test Case 2: Test with invalid start index
    func testConcatenateStringArrayInvalidIndex() {
        let invalidStartIndex = -1
        let invalidEndIndex = 2
        let inputArray = ["Hello", " ", "World", "!"]
        let container = skyflow.container(type: ContainerType.COMPOSABLE)

        let invalidResult = container?.concatenateStringArray(inputArray, from: invalidStartIndex, to: invalidEndIndex)
        XCTAssertEqual(invalidResult, "")
    }
    // Test Case 3: Test with invalid end index
    func testConcatenateStringArrayInvalidEndIndex() {
        let anotherInvalidStartIndex = 0
        let anotherInvalidEndIndex = 10
        let inputArray = ["Hello", " ", "World", "!"]
        let container = skyflow.container(type: ContainerType.COMPOSABLE)
        
        let anotherInvalidResult = container?.concatenateStringArray(inputArray, from: anotherInvalidStartIndex, to: anotherInvalidEndIndex)
        XCTAssertEqual(anotherInvalidResult, "")
    }
    func testConcatenateStringArrayEmpty (){
        let emptyArray = [String]()
        let container = skyflow.container(type: ContainerType.COMPOSABLE)
        let emptyResult = container?.concatenateStringArray(emptyArray, from: 0, to: 2)
        XCTAssertEqual(emptyResult, "")
    }
    func testConcatenateStringArrayRveresedIndex(){
        let reversedStartIndex = 3
        let reversedEndIndex = 1
        let inputArray = ["Hello", " ", "World", "!"]
        let container = skyflow.container(type: ContainerType.COMPOSABLE)
        let reversedResult = container?.concatenateStringArray(inputArray, from: reversedStartIndex, to: reversedEndIndex)
        XCTAssertEqual(reversedResult, "")
    }
    func testSubmitOnEnter(){
        let window = UIWindow()
        var submit = false
        let container = skyflow.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))

        let options = CollectElementOptions(required: true)
        
        let collectInput = CollectElementInput(table: "persons", column: "cardnumber", placeholder: "card number", type: .CARD_NUMBER)
        
        let cardNumber = container?.create(input: collectInput, options: options)
        do {
            let view = try container?.getComposableView()
            window.addSubview(view!)
           let value = cardNumber?.textField.delegate?.textFieldShouldReturn?(cardNumber!.textField)
            
            container?.on(eventName: .SUBMIT){
                submit = true
            }
            TextFieldValidationDelegate(collectField: cardNumber!).textFieldShouldReturn(cardNumber!.textField)
            XCTAssertTrue(value! as Bool)
            XCTAssertTrue(submit)
        } catch {
            print(error)
        }
    }
    
}
