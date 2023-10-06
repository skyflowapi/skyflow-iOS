//
//  RevealSkyflowLabelViewTests.swift
//  
//
//  Created by Bharti Sagar on 19/04/23.
//

import Foundation
import XCTest
import AEXML
@testable import Skyflow

class RevealSkyflowLabelViewTests: XCTestCase {
    
    func testSkyflowLabelViewUpdateValMethod(){
        let label = Label(input: RevealElementInput(token: "token", label: "label"), options: RevealElementOptions())
        label.updateVal(value: "123")
        XCTAssertEqual(label.getValue(), "123")
        XCTAssertEqual(label.actualValue, "123")
    }
    func testSkyflowLabelViewUpdateValMethodWithEmptyFormatTranslation(){
        let label = Label(input: RevealElementInput(token: "token", label: "label"), options: RevealElementOptions(format: ""))
        label.updateVal(value: "123")
        XCTAssertEqual(label.actualValue, "123")
    }

    func testSkyflowLabelViewUpdateValMethodWithFormatEmptyTranslation(){
        let config = Skyflow.Configuration(vaultID: "vault id", vaultURL:"vault url", tokenProvider: DemoTokenProvider(), options: Skyflow.Options(env: Skyflow.Env.DEV))

        // Initialize skyflow client
        let skyflowClient = Skyflow.initialize(config)

        // Create a Reveal Container
        let container = skyflowClient.container(type: Skyflow.ContainerType.REVEAL)
        // Create Reveal Elements
        let cardNumberInput = Skyflow.RevealElementInput(
            token: "b63ec4e0-bbad-4e43-96e6-6bd50f483f75",
            label: "cardnumber",
            altText: "XXXX XXXX XXXX XXXX"
        )

        let cardNumberElement = container?.create(input: cardNumberInput, options: RevealElementOptions(format: "X-X-X-X-X"))
        cardNumberElement?.updateVal(value: "12345")
        XCTAssertEqual(cardNumberElement?.skyflowLabelView.label.secureText, "1-2-3-4-5")
        XCTAssertEqual(cardNumberElement?.actualValue, "12345")
        XCTAssertEqual(cardNumberElement?.getValue(), "12345")
    }
    func testSkyflowLabelViewFormatInputMethodWithEmptyFormatTranslation(){
        let label = Label(input: RevealElementInput(token: "token", label: "label"), options: RevealElementOptions())
        let result = label.formatInput(input: "1234", format: "X-X-X-X", translation: ["X": "[0-9]"])
        XCTAssertEqual(result, "1-2-3-4")
    }
    func testSkyflowLabelViewFormatInputMethodCase2(){
        let label = Label(input: RevealElementInput(token: "token", label: "label"), options: RevealElementOptions())
        let result = label.formatInput(input: "", format: "X-X-X-X", translation: ["X": "[0-9]"])
        XCTAssertEqual(result, "")
    }
    func testSkyflowLabelViewFormatInputMethodCase3(){ // when reveal data is less than format length
        let label = Label(input: RevealElementInput(token: "token", label: "label"), options: RevealElementOptions())
        let result = label.formatInput(input: "123", format: "X-X-X-X", translation: ["X": "[0-9]"])
        XCTAssertEqual(result, "1-2-3")
    }
    func testSkyflowLabelViewFormatInputMethodCase4(){ // when reveal data is greater than format length
        let label = Label(input: RevealElementInput(token: "token", label: "label"), options: RevealElementOptions())
        let result = label.formatInput(input: "12345", format: "X-X-X-X", translation: ["X": "[0-9]"])
        XCTAssertEqual(result, "1-2-3-4")
    }
    func testSkyflowLabelViewFormatInputMethodCase5(){ // when translation doesnt contain format character
        let label = Label(input: RevealElementInput(token: "token", label: "label"), options: RevealElementOptions())
        let result = label.formatInput(input: "12345", format: "X-X-X-X", translation: ["Y": "[0-9]"])
        XCTAssertEqual(result, "X-X-X-X")
    }
    func testSkyflowLabelViewFormatInputMethodCase6(){ // when translation doesnt contain format character
        let label = Label(input: RevealElementInput(token: "token", label: "label"), options: RevealElementOptions())
        let result = label.formatInput(input: "12345", format: "", translation: ["X": "[0-9]"])
        XCTAssertEqual(result, "")
    }
    func testSkyflowLabelViewFormatInputMethodCase7(){ // when reveal data is not same as regex in translation
        let label = Label(input: RevealElementInput(token: "token", label: "label"), options: RevealElementOptions())
        let result = label.formatInput(input: "12345", format: "XXXX", translation: ["X": "[A-Z]"])
        XCTAssertEqual(result, "")
    }
    func testSkyflowLabelViewFormatInputMethodCase8(){ // when reveal data is not same as regex in translation
        let label = Label(input: RevealElementInput(token: "token", label: "label"), options: RevealElementOptions())
        let result = label.formatInput(input: "ZA", format: "XXXX", translation: ["X": "[ZA]"])
        XCTAssertEqual(result, "ZA")
    }
    func testSkyflowLabelViewFormatInputMethodCase9(){ // when reveal data type is not same as regex in translation
        let label = Label(input: RevealElementInput(token: "token", label: "label"), options: RevealElementOptions())
        let result = label.formatInput(input: "ZA", format: "XXXX", translation: ["X": "[-]"])
        XCTAssertEqual(result, "")
    }
    
    func testCopyEnabled() {
        let label = SkyflowLabelView( input: RevealElementInput(token: "token", label: "label"), options: RevealElementOptions(enableCopy: true))
        label.updateVal(value: "demo", actualValue: "demo")
        XCTAssertTrue(label.label.copyAfterReveal)
        }

    func testCopyDisabled() {
        let label = SkyflowLabelView( input: RevealElementInput(token: "token", label: "label"), options: RevealElementOptions(enableCopy: false))
        label.updateVal(value: "demo", actualValue: nil)
        XCTAssertTrue(label.label.copyAfterReveal == false)
        }

//    func testCopyIconTapped() {
//        let label = SkyflowLabelView( input: RevealElementInput(token: "token", label: "label"), options: RevealElementOptions(enableCopy: true))
//        label.label.text = "Hello, World!"
//        label.updateVal(value: "demo", actualValue: "value")
//        XCTAssertTrue(label.label.copyAfterReveal)
//        label.label.copyAfterReveal = true
//        XCTAssertTrue(label.label.actualValue == "value")
//
//        label.label.copyIconTapped(UITapGestureRecognizer())
//
//        XCTAssertEqual(UIPasteboard.general.string, "Hello, World!")
//    }
}
