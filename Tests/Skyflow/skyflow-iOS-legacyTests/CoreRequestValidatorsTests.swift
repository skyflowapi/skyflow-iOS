/*
 * Copyright (c) 2022 Skyflow
*/

// Direct tests for SkyflowCore.CoreRequestValidators: the contract-agnostic
// pre-flight validators shared by both SDKs' client and container operations
// (introduced by the SK-3043 common-code refactor). Exercised here via the
// legacy (v1) Client/Container since the functions themselves are contract-agnostic.

import UIKit
import XCTest
@testable import Skyflow
@testable import SkyflowCore

final class CoreRequestValidatorsTests: XCTestCase {
    var skyflow: Client!

    override func setUp() {
        self.skyflow = Client(Configuration(
            vaultID: "vault_id",
            vaultURL: "https://example.org/",
            tokenProvider: DemoTokenProvider(),
            options: Options(logLevel: .DEBUG)))
    }

    override func tearDown() {
        skyflow = nil
    }

    private func assertError(_ actual: ErrorCodes?, _ expected: ErrorCodes) {
        XCTAssertEqual(actual?.getErrorObject(contextOptions: ContextOptions()).localizedDescription,
                       expected.getErrorObject(contextOptions: ContextOptions()).localizedDescription)
    }

    // MARK: - checkClientConfig

    func testCheckClientConfigValid() {
        XCTAssertNil(CoreRequestValidators.checkClientConfig(vaultID: "vault_id", vaultURL: "https://example.org/"))
    }

    func testCheckClientConfigEmptyVaultID() {
        assertError(CoreRequestValidators.checkClientConfig(vaultID: "", vaultURL: "https://example.org/"),
                    .EMPTY_VAULT_ID())
    }

    func testCheckClientConfigEmptyVaultURL() {
        // An empty vaultURL is normalized to "/" by SkyflowCore.Client before reaching validators.
        assertError(CoreRequestValidators.checkClientConfig(vaultID: "vault_id", vaultURL: "/"),
                    .EMPTY_VAULT_URL())
    }

    // MARK: - checkElement

    func testCheckElementValidMountedElement() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let element = container!.create(input: CollectElementInput(table: "persons", column: "name", type: .CARDHOLDER_NAME))
        UIWindow().addSubview(element)

        XCTAssertNil(CoreRequestValidators.checkElement(element: element))
    }

    func testCheckElementEmptyTableName() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let element = container!.create(input: CollectElementInput(table: "", column: "name", type: .CARDHOLDER_NAME))

        assertError(CoreRequestValidators.checkElement(element: element), .EMPTY_TABLE_NAME_IN_COLLECT())
    }

    func testCheckElementEmptyColumnName() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let element = container!.create(input: CollectElementInput(table: "persons", column: "", type: .CARDHOLDER_NAME))

        assertError(CoreRequestValidators.checkElement(element: element), .EMPTY_COLUMN_NAME_IN_COLLECT())
    }

    func testCheckElementUnmounted() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let element = container!.create(input: CollectElementInput(table: "persons", column: "name", type: .CARDHOLDER_NAME))
        // Not added to any window/view hierarchy: isMounted() is false.

        assertError(CoreRequestValidators.checkElement(element: element), .UNMOUNTED_COLLECT_ELEMENT(value: "name"))
    }

    // MARK: - checkRevealElements / checkRevealElementsPreflight

    func testCheckRevealElementsValid() {
        let container = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let element = container!.create(input: RevealElementInput(token: "token1", label: "first"))

        XCTAssertNil(CoreRequestValidators.checkRevealElements(elements: [element]))
    }

    func testCheckRevealElementsEmptyToken() {
        let container = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let element = container!.create(input: RevealElementInput(token: "", label: "first"))

        assertError(CoreRequestValidators.checkRevealElements(elements: [element]), .EMPTY_TOKEN_ID())
    }

    func testCheckRevealElementsErrorTriggered() {
        let container = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let element = container!.create(input: RevealElementInput(token: "token1", label: "first"))
        element.setError("custom trigger message")

        assertError(CoreRequestValidators.checkRevealElements(elements: [element]), .ERROR_TRIGGERED(value: "custom trigger message"))
    }

    func testCheckRevealElementsErrorTriggeredTakesPrecedenceOverEmptyToken() {
        let container = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let element = container!.create(input: RevealElementInput(token: "", label: "first"))
        element.setError("custom trigger message")

        // errorTriggered is checked before the empty-token check for the same element.
        assertError(CoreRequestValidators.checkRevealElements(elements: [element]), .ERROR_TRIGGERED(value: "custom trigger message"))
    }

    func testCheckRevealElementsPreflightUnmounted() {
        let container = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let element = container!.create(input: RevealElementInput(token: "token1", label: "first"))
        // Not mounted.

        assertError(CoreRequestValidators.checkRevealElementsPreflight(elements: [element]), .UNMOUNTED_REVEAL_ELEMENT(value: "token1"))
    }

    func testCheckRevealElementsPreflightMountedValid() {
        let container = skyflow.container(type: ContainerType.REVEAL, options: nil)
        let element = container!.create(input: RevealElementInput(token: "token1", label: "first"))
        UIWindow().addSubview(element)

        XCTAssertNil(CoreRequestValidators.checkRevealElementsPreflight(elements: [element]))
    }

    // MARK: - validateElementStates

    func testValidateElementStatesAllValid() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let element = container!.create(input: CollectElementInput(table: "persons", column: "name", type: .CARDHOLDER_NAME))
        UIWindow().addSubview(element)

        let result = CoreRequestValidators.validateElementStates(elements: [element])
        XCTAssertNil(result.errorCode)
        XCTAssertEqual(result.errors, "")
    }

    func testValidateElementStatesEmptyRequiredElement() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let element = container!.create(input: CollectElementInput(table: "persons", column: "name", type: .CARDHOLDER_NAME),
                                        options: CollectElementOptions(required: true))
        UIWindow().addSubview(element)

        let result = CoreRequestValidators.validateElementStates(elements: [element])
        XCTAssertNil(result.errorCode)
        XCTAssertTrue(result.errors.contains("name is empty"))
    }

    func testValidateElementStatesFailsFastOnElementError() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let unmounted = container!.create(input: CollectElementInput(table: "persons", column: "name", type: .CARDHOLDER_NAME))
        // Not mounted: checkElement fails before any per-element state accounting.

        let result = CoreRequestValidators.validateElementStates(elements: [unmounted])
        assertError(result.errorCode, .UNMOUNTED_COLLECT_ELEMENT(value: "name"))
        XCTAssertEqual(result.errors, "")
    }

    // MARK: - checkInsertRecordEntries

    func testCheckInsertRecordEntriesValid() {
        let entries: [[String: Any]] = [["table": "persons", "fields": ["name": "john"]]]
        XCTAssertNil(CoreRequestValidators.checkInsertRecordEntries(entries))
    }

    func testCheckInsertRecordEntriesMissingTableKey() {
        let entries: [[String: Any]] = [["fields": ["name": "john"]]]
        assertError(CoreRequestValidators.checkInsertRecordEntries(entries), .TABLE_KEY_ERROR(value: "0"))
    }

    func testCheckInsertRecordEntriesInvalidTableType() {
        let entries: [[String: Any]] = [["table": 1, "fields": ["name": "john"]]]
        assertError(CoreRequestValidators.checkInsertRecordEntries(entries), .INVALID_TABLE_NAME_TYPE(value: "0"))
    }

    func testCheckInsertRecordEntriesEmptyTableName() {
        let entries: [[String: Any]] = [["table": "", "fields": ["name": "john"]]]
        assertError(CoreRequestValidators.checkInsertRecordEntries(entries), .EMPTY_TABLE_NAME())
    }

    func testCheckInsertRecordEntriesMissingFieldsKey() {
        let entries: [[String: Any]] = [["table": "persons"]]
        assertError(CoreRequestValidators.checkInsertRecordEntries(entries), .FIELDS_KEY_ERROR(value: "0"))
    }

    func testCheckInsertRecordEntriesInvalidFieldsType() {
        let entries: [[String: Any]] = [["table": "persons", "fields": "not a dict"]]
        assertError(CoreRequestValidators.checkInsertRecordEntries(entries), .INVALID_FIELDS_TYPE(value: "0"))
    }

    func testCheckInsertRecordEntriesEmptyFields() {
        let entries: [[String: Any]] = [["table": "persons", "fields": [:] as [String: Any]]]
        assertError(CoreRequestValidators.checkInsertRecordEntries(entries), .EMPTY_FIELDS_KEY(value: "0"))
    }

    func testCheckInsertRecordEntriesLastErrorWinsAcrossMultipleRecords() {
        // Matches the original per-SDK loop's semantics: the loop doesn't break on most
        // error kinds, so with multiple invalid records the *last* one's error wins.
        let entries: [[String: Any]] = [
            ["fields": ["name": "john"]],              // TABLE_KEY_ERROR at index 0
            ["table": "", "fields": ["name": "jane"]]  // EMPTY_TABLE_NAME at index 1 -- wins
        ]
        assertError(CoreRequestValidators.checkInsertRecordEntries(entries), .EMPTY_TABLE_NAME())
    }

    func testCheckInsertRecordEntriesInvalidFieldsTypeStopsScan() {
        // INVALID_FIELDS_TYPE is the one branch that `break`s out of the loop, so a
        // later record's error must not overwrite it.
        let entries: [[String: Any]] = [
            ["table": "persons", "fields": "not a dict"], // INVALID_FIELDS_TYPE at index 0, then break
            ["fields": ["name": "jane"]]                  // would be TABLE_KEY_ERROR at index 1 if reached
        ]
        assertError(CoreRequestValidators.checkInsertRecordEntries(entries), .INVALID_FIELDS_TYPE(value: "0"))
    }
}
