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
@testable import SkyflowFlowVaultIOS
@testable import SkyflowCore

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
        XCTAssertEqual(textfield.description, NSStringFromClass(FormatTextField.self))
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

    func testSkyflowErrorWrapReturnsExistingInstanceUnchanged() {
        let original = SkyflowError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "original message"])
        let wrapped = SkyflowError.wrap(original)
        XCTAssertTrue(wrapped === original)
    }

    func testSkyflowErrorWrapPreservesPlainNSError() {
        let nsError = NSError(domain: "NSURLErrorDomain", code: -1009, userInfo: [NSLocalizedDescriptionKey: "The Internet connection appears to be offline."])
        let wrapped = SkyflowError.wrap(nsError)

        XCTAssertEqual(wrapped.domain, "NSURLErrorDomain")
        XCTAssertEqual(wrapped.httpCode, -1009)
        XCTAssertEqual(wrapped.message, "The Internet connection appears to be offline.")
        XCTAssertNil(wrapped.grpcCode)
        XCTAssertNil(wrapped.httpStatus)
        XCTAssertNil(wrapped.details)
    }

    func testSkyflowErrorWrapFallsBackForOpaqueValue() {
        // Anything that isn't a SkyflowError, the structured {"error": {...}} API shape, an
        // NSError, or the internal {"errors": [...]} wrapping still needs to produce *something*
        // usable rather than crash.
        let wrapped = SkyflowError.wrap("just a plain string, not an error at all")
        XCTAssertEqual(wrapped.httpCode, 0)
        XCTAssertTrue(wrapped.message.contains("just a plain string"))
    }

    func testSkyflowAPIErrorInitMissingOptionalFields() {
        let apiError: [String: Any] = [
            "error": ["httpCode": 500, "message": "Internal error"]
        ]
        let skyflowError = SkyflowError(apiError: apiError)

        XCTAssertEqual(skyflowError?.httpCode, 500)
        XCTAssertEqual(skyflowError?.message, "Internal error")
        XCTAssertNil(skyflowError?.grpcCode)
        XCTAssertNil(skyflowError?.httpStatus)
        XCTAssertNil(skyflowError?.details)
    }

    func testSkyflowAPIErrorInitReturnsNilForMalformedInput() {
        XCTAssertNil(SkyflowError(apiError: "not a dictionary"))
        XCTAssertNil(SkyflowError(apiError: ["message": "no nested error key"]))
    }

    func testSkyflowErrorWrapRecoversNSErrorFromNestedErrorsArray() {
        // Mirrors what FlowVaultRevealAPICallback.callRevealOnFailure produces for a
        // whole-request failure reaching Client.detokenize() directly (no RevealValueCallback
        // in between to unwrap it first).
        let underlying = NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid bearer token"])
        let wrapped = SkyflowError.wrap(["errors": [["error": underlying]]])
        XCTAssertEqual(wrapped.httpCode, 400)
        XCTAssertEqual(wrapped.message, "Invalid bearer token")
    }
}

