/*
 * Copyright (c) 2025 Skyflow
*/

// Tests for SkyflowCore's shared, contract-agnostic logic. This bundle
// depends ONLY on SkyflowCore — no SDK target — so it stays green (or red)
// independently of either SDK's setup, and it physically cannot grow a
// dependency on contract-specific types.

import XCTest
@testable import SkyflowCore

final class CoreLogicTests: XCTestCase {
    // MARK: - CardType detection

    func testCardTypeDetection() {
        XCTAssertEqual(CardType.forCardNumber(cardNumber: "4111111111111111"), CardType.VISA)
        XCTAssertEqual(CardType.forCardNumber(cardNumber: "5555555555554444"), CardType.MASTERCARD)
        XCTAssertEqual(CardType.forCardNumber(cardNumber: "378282246310005"), CardType.AMEX)
        XCTAssertEqual(CardType.forCardNumber(cardNumber: "6011111111111117"), CardType.DISCOVER)
    }

    // MARK: - Card number validation (Luhn)

    func testCardNumberValidator() {
        // The regex is matched against the raw input (separators included)
        // before the card-length and Luhn checks run.
        let validator = SkyflowValidateCardNumber(error: "invalid card", regex: "^[0-9 -]+$")

        XCTAssertTrue(validator.validate("4111111111111111"))
        // Separators are stripped before validating.
        XCTAssertTrue(validator.validate("4111 1111 1111 1111"))
        XCTAssertTrue(validator.validate("4111-1111-1111-1111"))
        // Luhn checksum failure.
        XCTAssertFalse(validator.validate("4111111111111112"))
        // Documented behavior: empty input is not an error at this layer
        // (emptiness is handled by the required-field check).
        XCTAssertTrue(validator.validate(""))
    }

    // MARK: - Expiration month validation

    func testExpirationMonthValidator() {
        let validator = SkyflowValidateExpirationMonth(error: "invalid month")

        XCTAssertTrue(validator.validate("1"))
        XCTAssertTrue(validator.validate("01"))
        XCTAssertTrue(validator.validate("12"))
        XCTAssertFalse(validator.validate("13"))
        XCTAssertFalse(validator.validate("123"))
        XCTAssertFalse(validator.validate("ab"))
        XCTAssertTrue(validator.validate(""))
    }

    // MARK: - Public validation rules

    func testLengthMatchRule() {
        let rule = LengthMatchRule(minLength: 2, maxLength: 4, error: "bad length")

        XCTAssertTrue(rule.validate("ab"))
        XCTAssertTrue(rule.validate("abcd"))
        XCTAssertFalse(rule.validate("a"))
        XCTAssertFalse(rule.validate("abcde"))
    }

    func testRegexMatchRule() {
        let rule = RegexMatchRule(regex: "^[0-9]+$", error: "digits only")

        XCTAssertTrue(rule.validate("12345"))
        XCTAssertFalse(rule.validate("12a45"))
    }

    // MARK: - CoreRequestValidators (shared pre-flight checks)

    private func message(_ errorCode: ErrorCodes) -> String {
        return errorCode.getErrorObject(contextOptions: ContextOptions()).localizedDescription
    }

    func testCheckClientConfig() {
        XCTAssertNil(CoreRequestValidators.checkClientConfig(
            vaultID: "vault", vaultURL: "https://example.org/v1/vaults/"))

        let emptyID = CoreRequestValidators.checkClientConfig(vaultID: "", vaultURL: "https://example.org/")
        XCTAssertEqual(message(emptyID!), message(ErrorCodes.EMPTY_VAULT_ID()))

        // An empty vaultURL becomes "/" in SkyflowCore.Client.
        let emptyURL = CoreRequestValidators.checkClientConfig(vaultID: "vault", vaultURL: "/")
        XCTAssertEqual(message(emptyURL!), message(ErrorCodes.EMPTY_VAULT_URL()))
    }

    func testCheckInsertRecordEntries() {
        let valid: [[String: Any]] = [["table": "cards", "fields": ["cvv": "123"]]]
        XCTAssertNil(CoreRequestValidators.checkInsertRecordEntries(valid))

        let missingTable: [[String: Any]] = [["fields": ["cvv": "123"]]]
        XCTAssertEqual(message(CoreRequestValidators.checkInsertRecordEntries(missingTable)!),
                       message(ErrorCodes.TABLE_KEY_ERROR(value: "0")))

        let emptyTable: [[String: Any]] = [["table": "", "fields": ["cvv": "123"]]]
        XCTAssertEqual(message(CoreRequestValidators.checkInsertRecordEntries(emptyTable)!),
                       message(ErrorCodes.EMPTY_TABLE_NAME()))

        let missingFields: [[String: Any]] = [["table": "cards"]]
        XCTAssertEqual(message(CoreRequestValidators.checkInsertRecordEntries(missingFields)!),
                       message(ErrorCodes.FIELDS_KEY_ERROR(value: "0")))

        let wrongFieldsType: [[String: Any]] = [["table": "cards", "fields": "not-a-dict"]]
        XCTAssertEqual(message(CoreRequestValidators.checkInsertRecordEntries(wrongFieldsType)!),
                       message(ErrorCodes.INVALID_FIELDS_TYPE(value: "0")))

        let emptyFields: [[String: Any]] = [["table": "cards", "fields": [String: Any]()]]
        XCTAssertEqual(message(CoreRequestValidators.checkInsertRecordEntries(emptyFields)!),
                       message(ErrorCodes.EMPTY_FIELDS_KEY(value: "0")))
    }
}
