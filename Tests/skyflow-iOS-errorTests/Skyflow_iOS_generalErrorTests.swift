/*
 * Copyright (c) 2022 Skyflow
*/

//
//  Skyflow_iOS_generalErrorTests.swift
//  skyflow-iOS-errorTests
//
//  Created by Tejesh Reddy Allampati on 20/10/21.
//

import XCTest
@testable import Skyflow

// swiftlint:disable:next type_body_length
class Skyflow_iOS_generalErrorTests: XCTestCase {

    
    func testMessage() {
        let message = Message.CLIENT_CONNECTION
        
        XCTAssertEqual(message.getDescription(values: []), "client connection not established")
    }
    
    func testSkyflowValidateLength() {
        let lengthRule = LengthMatchRule(minLength: 10, maxLength: 20, error: SkyflowValidationErrorType.lengthMatches.rawValue)
        
        XCTAssertEqual(lengthRule.error, SkyflowValidationErrorType.lengthMatches.rawValue)
        XCTAssertEqual(lengthRule.maxLength, 20)
        XCTAssertEqual(lengthRule.minLength, 10)

        XCTAssertEqual(false, lengthRule.validate("abcde"))
        XCTAssertEqual(true, lengthRule.validate("abcdefghijklmno"))
        XCTAssertEqual(true, lengthRule.validate(""))
        XCTAssertEqual(false, lengthRule.validate(nil))
    }
    
    func testSkyflowValidateLengthMatch() {
        let lengthMatchRule = SkyflowValidateLengthMatch(lengths: [1, 4, 7, 10], error: SkyflowValidationErrorType.cardNumber.rawValue)
        
        XCTAssertEqual(lengthMatchRule.validate("4123"), true)
        XCTAssertEqual(lengthMatchRule.validate(""), true)
        XCTAssertEqual(lengthMatchRule.validate("123"), false)
        XCTAssertEqual(lengthMatchRule.validate(nil), false)
    }
    
    func testSkyflowValidateCardExpirationDate() {
        let expiryDaterRule = SkyflowValidateCardExpirationDate(format: "mm/yy", error: SkyflowValidationErrorType.expirationDate.rawValue)
        
        XCTAssertEqual(expiryDaterRule.validate("12/30"), true)
        
        XCTAssertEqual(expiryDaterRule.validate("12"), false)
        XCTAssertEqual(expiryDaterRule.validate("abc"), false)
        XCTAssertEqual(expiryDaterRule.validate("1222"), false)
        XCTAssertEqual(expiryDaterRule.validate("123/22"), false)
        XCTAssertEqual(expiryDaterRule.validate("12/2"), false)
    }
    
    func testSkyflowExpiryDateFormat() {
        let shortDateFormat = SkyflowCardExpirationDateFormat.shortYear
        let longDateFormat = SkyflowCardExpirationDateFormat.longYear
        
        XCTAssertEqual(shortDateFormat.dateYearFormat, "yy")
        XCTAssertEqual(shortDateFormat.monthCharacters, 2)
        XCTAssertEqual(shortDateFormat.yearCharacters, 2)
        XCTAssertEqual(longDateFormat.dateYearFormat, "yyyy")
        XCTAssertEqual(longDateFormat.yearCharacters, 4)
        
    }
    
    
    func testGetByIDRecord() {
        let record = GetByIdRecord(ids: ["id1", "id2"], table: "table", redaction: "DEFAULT")
        
        XCTAssertEqual(record.ids, ["id1", "id2"])
        XCTAssertEqual("table", record.table)
        XCTAssertEqual(record.redaction, "DEFAULT")
    }
    
    func testValidationSet() {
        let validationSet = ValidationSet(
            rules: [SkyflowValidateCardNumber(
                        error: SkyflowValidationErrorType.cardNumber.rawValue,
                        regex: "abcd"),
                    SkyflowValidateCardExpirationDate(
                        format: "mm/yy", error: SkyflowValidationErrorType.expirationDate.rawValue)
            ])
        
        XCTAssertEqual(validationSet.rules.count, 2)
        XCTAssertEqual(validationSet.rules[0].error, SkyflowValidationErrorType.cardNumber.rawValue)
        XCTAssertEqual(validationSet.rules[1].error, SkyflowValidationErrorType.expirationDate.rawValue)
        
    }
    
    func testFormatTextField() {
        let textfield = FormatTextField(frame: .zero)
        
        XCTAssertEqual(textfield.maxLength, 0)
        
        let textRect = textfield.textRect(forBounds: CGRect(x: 1, y: 2, width: 3, height: 4))
        let placeholderRect = textfield.placeholderRect(forBounds: CGRect(x: 4, y: 3, width: 2, height: 1))
        let editingRect = textfield.editingRect(forBounds: CGRect(x: 2, y: 4, width: 3, height: 1))
        
        XCTAssert(textRect.contains(CGPoint(x: 1, y: 2)))
        XCTAssert(placeholderRect.contains(CGPoint(x: 4, y: 3)))
        XCTAssert(editingRect.contains(CGPoint(x: 2, y: 4)))
        XCTAssertEqual(textfield.description, "Skyflow.FormatTextField")
    }
    
    func testState() {
        let state = State(columnName: "column", isRequired: true)
        let result = state.getState()
        
        XCTAssertEqual(state.columnName, "column")
        XCTAssertEqual(state.isRequired, true)
        XCTAssertEqual(state.show, """
        "column": {
            "isRequired": true
        }
        """)
        XCTAssertEqual(result["columnName"] as! String, "column")
        XCTAssertEqual(result["isRequired"] as! Bool, true)
    }
    
    func testLogs() {
        Log.debug(message: Message.BEARER_TOKEN_RECEIVED, contextOptions: ContextOptions())
        Log.warn(message: Message.CANNOT_CHANGE_ELEMENT, contextOptions: ContextOptions())
        Log.info(message: Message.CLIENT_INITIALIZED, contextOptions: ContextOptions())
        Log.error(message: ErrorCodes.INVALID_URL().description, contextOptions: ContextOptions())
    }
    
    func testPaddingLabel() {
        let label = PaddingLabel(frame: .zero)
        
        // Defaults
        XCTAssertEqual(label.intrinsicContentSize, CGSize(width: 0, height: 0))
        XCTAssertEqual(label.bounds, CGRect(x: 0, y: 0, width: 0, height: 0))
        XCTAssertEqual(label.insets, UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
        
        // changed bounds
        label.drawText(in: .zero)
        label.bounds = CGRect(x: 1, y: 1, width: 1, height: 1)
        XCTAssertEqual(label.preferredMaxLayoutWidth, 1)
    }
    
    func testIsTokenValid() {
        let apiClient = APIClient(vaultID: "", vaultURL: "", tokenProvider: DemoTokenProvider())
        let expectation = XCTestExpectation(description: "should get token")
        
        XCTAssertEqual(false, apiClient.isTokenValid())
    }
}

