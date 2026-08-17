/*
 * Copyright (c) 2022 Skyflow
*/

// Tests for the legacy (v1) collect layer: container collect() /
// composable collect() validation paths and the legacy option/input models
// (untyped additionalFields + upsert dictionaries, tokens flag).

import UIKit
import XCTest
@testable import Skyflow
@testable import SkyflowCore

final class skyflow_iOS_legacyCollectOpsTests: XCTestCase {
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

    // MARK: - Legacy option models

    func testCollectOptionsDefaults() {
        let options = CollectOptions()

        XCTAssertTrue(options.tokens)
        XCTAssertNil(options.additionalFields)
        XCTAssertNil(options.upsert)
    }

    func testInsertOptionsDefaults() {
        let options = InsertOptions()

        XCTAssertTrue(options.tokens)
        XCTAssertNil(options.upsert)
    }

    func testGetOptionsDefaults() {
        XCTAssertFalse(GetOptions().tokens)
        XCTAssertTrue(GetOptions(tokens: true).tokens)
    }

    func testCollectElementInputLegacyArgumentLabels() {
        // The legacy contract uses `table:` and `skyflowID:` labels (vs FlowVault's
        // `tableName:`/`skyflowId:`), mapped onto the shared base input.
        let input = CollectElementInput(table: "persons", column: "name", type: .CARDHOLDER_NAME, skyflowID: "sid-1")

        XCTAssertEqual(input.data.tableName, "persons")
        XCTAssertEqual(input.data.column, "name")
        XCTAssertEqual(input.data.skyflowId, "sid-1")
    }

    // MARK: - Container collect() validation

    func testCollectEmptyVaultURL() {
        let client = Client(Configuration(vaultID: "vault_id", vaultURL: "", tokenProvider: DemoTokenProvider()))
        let container = client.container(type: ContainerType.COLLECT, options: nil)

        let expectation = XCTestExpectation(description: "collect with empty vaultURL should fail")
        let callback = DemoAPICallback(expectation: expectation)
        container!.collect(callback: callback)

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.EMPTY_VAULT_URL().description)
    }

    func testCollectAdditionalFieldsMissingRecordsKey() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)

        let expectation = XCTestExpectation(description: "collect with malformed additionalFields should fail")
        let callback = DemoAPICallback(expectation: expectation)
        container!.collect(callback: callback, options: CollectOptions(additionalFields: ["norecords": []]))

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.MISSING_RECORDS_IN_ADDITIONAL_FIELDS().description)
    }

    func testCollectEmptyUpsertOptions() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)

        let expectation = XCTestExpectation(description: "collect with empty upsert array should fail")
        let callback = DemoAPICallback(expectation: expectation)
        let additionalFields: [String: Any] = ["records": [["table": "persons", "fields": ["name": "john"]]]]
        container!.collect(callback: callback, options: CollectOptions(additionalFields: additionalFields, upsert: []))

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.UPSERT_OPTION_CANNOT_BE_EMPTY().description)
    }

    func testCollectUpsertMissingColumn() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)

        let expectation = XCTestExpectation(description: "collect with column-less upsert should fail")
        let callback = DemoAPICallback(expectation: expectation)
        let additionalFields: [String: Any] = ["records": [["table": "persons", "fields": ["name": "john"]]]]
        container!.collect(callback: callback, options: CollectOptions(additionalFields: additionalFields, upsert: [["table": "persons"]]))

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.MISSING_COLUMN_NAME_IN_USERT_OPTION(value: "0").description)
    }

    // MARK: - Composable collect() validation

    func testComposableCollectEmptyVaultURL() {
        let client = Client(Configuration(vaultID: "vault_id", vaultURL: "", tokenProvider: DemoTokenProvider()))
        let container = client.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))

        let expectation = XCTestExpectation(description: "composable collect with empty vaultURL should fail")
        let callback = DemoAPICallback(expectation: expectation)
        container!.collect(callback: callback)

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.EMPTY_VAULT_URL().description)
    }

    func testComposableCollectAdditionalFieldsMissingRecordsKey() {
        let container = skyflow.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))

        let expectation = XCTestExpectation(description: "composable collect with malformed additionalFields should fail")
        let callback = DemoAPICallback(expectation: expectation)
        container!.collect(callback: callback, options: CollectOptions(additionalFields: ["norecords": []]))

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.MISSING_RECORDS_IN_ADDITIONAL_FIELDS().description)
    }

    // MARK: - collect()/composable collect() element-state branches and full flow

    // DemoTokenProvider's "dummy_token" isn't JWT-shaped, so isTokenValid() would reject
    // it and short-circuit the request with INVALID_BEARER_TOKEN_FORMAT before ever
    // reaching the network layer. offlineClient() needs a well-formed (if unverified)
    // token so requests actually get dispatched and fail at the DNS/network layer instead.
    private class ValidFormatTokenProvider: TokenProvider {
        func getBearerToken(_ apiCallback: Callback) {
            let payload = try! JSONSerialization.data(withJSONObject: ["exp": 9_999_999_999])
            apiCallback.onSuccess("header.\(payload.base64EncodedString()).signature")
        }
    }

    // Client whose vault host cannot resolve, so full-flow tests fail fast at the
    // network layer after exercising the entire request-building path.
    private func offlineClient() -> Client {
        return Client(Configuration(vaultID: "vault_id", vaultURL: "https://testvault.skyflow.invalid/",
                                    tokenProvider: ValidFormatTokenProvider()))
    }

    func testCollectUnmountedElementFails() {
        let client = offlineClient()
        let container = client.container(type: ContainerType.COLLECT, options: nil)
        _ = container!.create(input: CollectElementInput(table: "persons", column: "name", type: .CARDHOLDER_NAME))

        let expectation = XCTestExpectation(description: "collect with unmounted element should fail")
        let callback = DemoAPICallback(expectation: expectation)
        container!.collect(callback: callback)

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.UNMOUNTED_COLLECT_ELEMENT(value: "name").description)
    }

    func testCollectEmptyRequiredElementReportsValidationErrors() {
        let client = offlineClient()
        let container = client.container(type: ContainerType.COLLECT, options: nil)
        let element = container!.create(input: CollectElementInput(table: "persons", column: "name", type: .CARDHOLDER_NAME),
                                        options: CollectElementOptions(required: true))
        UIWindow().addSubview(element)

        let expectation = XCTestExpectation(description: "collect with empty required element should fail")
        let callback = DemoAPICallback(expectation: expectation)
        container!.collect(callback: callback)

        wait(for: [expectation], timeout: 10.0)
        XCTAssertTrue(callback.receivedResponse.contains("name is empty"))
    }

    func testCollectValidElementRunsFullRequestFlow() {
        let client = offlineClient()
        let container = client.container(type: ContainerType.COLLECT, options: nil)
        let element = container!.create(input: CollectElementInput(table: "persons", column: "name", type: .CARDHOLDER_NAME))
        element.textField.secureText = "John"
        UIWindow().addSubview(element)

        let expectation = XCTestExpectation(description: "collect should reach the network layer and fail offline")
        let callback = DemoAPICallback(expectation: expectation)
        container!.collect(callback: callback, options: CollectOptions(upsert: [["table": "persons", "column": "name"]]))

        wait(for: [expectation], timeout: 20.0)
        XCTAssertNotNil(callback.data["errors"])
    }

    func testComposableCreateAndCollectUnmountedElementFails() {
        let client = offlineClient()
        let container = client.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))
        _ = container!.create(input: CollectElementInput(table: "persons", column: "name", type: .CARDHOLDER_NAME))

        let expectation = XCTestExpectation(description: "composable collect with unmounted element should fail")
        let callback = DemoAPICallback(expectation: expectation)
        container!.collect(callback: callback)

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.UNMOUNTED_COLLECT_ELEMENT(value: "name").description)
    }

    func testComposableCollectEmptyRequiredElementReportsValidationErrors() {
        let client = offlineClient()
        let container = client.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))
        let element = container!.create(input: CollectElementInput(table: "persons", column: "name", type: .CARDHOLDER_NAME),
                                        options: CollectElementOptions(required: true))
        UIWindow().addSubview(element)

        let expectation = XCTestExpectation(description: "composable collect with empty required element should fail")
        let callback = DemoAPICallback(expectation: expectation)
        container!.collect(callback: callback)

        wait(for: [expectation], timeout: 10.0)
        XCTAssertTrue(callback.receivedResponse.contains("name is empty"))
    }

    func testComposableCollectValidElementRunsFullRequestFlow() {
        let client = offlineClient()
        let container = client.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))
        let element = container!.create(input: CollectElementInput(table: "persons", column: "name", type: .CARDHOLDER_NAME))
        element.textField.secureText = "John"
        UIWindow().addSubview(element)

        let expectation = XCTestExpectation(description: "composable collect should reach the network layer and fail offline")
        let callback = DemoAPICallback(expectation: expectation)
        container!.collect(callback: callback, options: CollectOptions(upsert: [["table": "persons", "column": "name"]]))

        wait(for: [expectation], timeout: 20.0)
        XCTAssertNotNil(callback.data["errors"])
    }

    // MARK: - Legacy model init overloads and update extensions

    func testCollectElementInputInitWithoutType() {
        let input = CollectElementInput(table: "persons", column: "name")

        XCTAssertEqual(input.data.tableName, "persons")
        XCTAssertEqual(input.data.column, "name")
        XCTAssertNil(input.data.type)
    }

    @available(*, deprecated) // silences the warning for exercising the deprecated altText: initializer
    func testCollectElementInputDeprecatedAltTextInit() {
        let input = CollectElementInput(table: "persons", column: "name", altText: "alt", type: .CARDHOLDER_NAME)

        XCTAssertEqual(input.data.tableName, "persons")
        XCTAssertEqual(input.data.column, "name")
    }

    func testTextFieldUpdateWithInputAndOptions() {
        let container = skyflow.container(type: ContainerType.COLLECT, options: nil)
        let element = container!.create(input: CollectElementInput(table: "persons", column: "name", type: .CARDHOLDER_NAME))

        element.update(update: CollectElementInput(table: "persons", column: "last_name", type: .CARDHOLDER_NAME))
        element.update(updateOptions: CollectElementOptions(required: true))

        XCTAssertEqual(element.collectInput.column, "last_name")
    }

    func testContainerOptionsEmptyInit() {
        let options = ContainerOptions()

        XCTAssertNotNil(options.data)
    }
}
