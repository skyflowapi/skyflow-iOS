//
//  Skyflow_iOS_gatewayErrorTests.swift
//  skyflow-iOS-errorTests
//
//  Created by Tejesh Reddy Allampati on 11/10/21.
//

import XCTest
@testable import Skyflow

class Skyflow_iOS_gatewayErrorTests: XCTestCase {
    var skyflow: Client!

    override func setUp() {
        self.skyflow = Client(Configuration(vaultID: ProcessInfo.processInfo.environment["VAULT_ID"]!, vaultURL: ProcessInfo.processInfo.environment["VAULT_URL"]!, tokenProvider: DemoTokenProvider()))
    }

    override func tearDown() {
        skyflow = nil
    }

    func getElements() -> (cardNumber: TextField, revealElement: Label) {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let revealContainer = skyflow.container(type: ContainerType.REVEAL, options: nil)

        let bstyle = Style(borderColor: UIColor.blue, cornerRadius: 20, padding: UIEdgeInsets(top: 15, left: 12, bottom: 15, right: 5), borderWidth: 2, textColor: UIColor.blue)

        let styles = Styles(base: bstyle)

        let options = CollectElementOptions(required: false)

        let collectInput = CollectElementInput(table: "persons", column: "cardNumber", inputStyles: styles, placeholder: "card number", type: .CARD_NUMBER)

        let cardNumber = container!.create(input: collectInput, options: options)
        cardNumber.textField.secureText = "4111-1111-1111-1111"

        let revealInput = RevealElementInput(token: "abc", inputStyles: styles, label: "reveal", redaction: .DEFAULT, altText: "reveal")
        let revealElement = revealContainer?.create(input: revealInput)

        return (cardNumber: cardNumber, revealElement: revealElement!)
    }

    func getError(_ data: [String: Any]) -> String {
        return (data["errors"] as! [NSError])[0].localizedDescription
    }

    func testInvokeGatewayUnmountedRequestElements() {
        let window = UIWindow()

        let (cardNumber, revealElement) = getElements()

        window.addSubview(revealElement)

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

        let expectation = XCTestExpectation(description: "should return response")
        let callback = GatewayAPICallback(expectation: expectation)
        self.skyflow.invokeGateway(config: gatewayConfig, callback: callback)

        wait(for: [expectation], timeout: 10.0)

        XCTAssertEqual(getError(callback.data), ErrorCodes.UNMOUNTED_COLLECT_ELEMENT(value: "cardNumber").description)
    }

    func testInvokeGatewayDuplicateElements() {
        let window = UIWindow()

        let (cardNumber, revealElement) = getElements()

        window.addSubview(revealElement)
        window.addSubview(cardNumber)

        let requestBody: [String: Any] = [
            "card_number": cardNumber,
            "holder_name": "john doe",
            "reveal": revealElement as Any,
            "nestedFields": [
                "card_number": cardNumber
            ]
        ]

        let gatewayConfig = GatewayConfig(gatewayURL: "https://skyflow.com/", method: .POST, requestBody: requestBody, responseBody: requestBody)

        let expectation = XCTestExpectation(description: "should return response")
        let callback = GatewayAPICallback(expectation: expectation)
        self.skyflow.invokeGateway(config: gatewayConfig, callback: callback)

        wait(for: [expectation], timeout: 10.0)

        XCTAssertEqual(getError(callback.data), ErrorCodes.DUPLICATE_ELEMENT_IN_RESPONSE_BODY(value: "").description)
    }
}
