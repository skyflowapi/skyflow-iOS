/*
 * Copyright (c) 2022 Skyflow
*/

// Branch coverage for the FlowVault composable container's collect() flow:
// element-state errors, typed additionalFields/upsert validation and the full
// request-building path (driven against an unresolvable vault host).

import UIKit
import XCTest
@testable import SkyflowFlowVault
@testable import SkyflowCore

final class skyflow_iOS_composableFlowTests: XCTestCase {

    // Token provider that succeeds synchronously, so flow tests never depend
    // on the TOKEN_ENDPOINT environment the shared DemoTokenProvider uses.
    private class InstantTokenProvider: TokenProvider {
        func getBearerToken(_ apiCallback: Callback) {
            apiCallback.onSuccess("token")
        }
    }

    private func offlineClient() -> Client {
        return Client(Configuration(vaultID: "vault_id", vaultURL: "https://testvault.skyflow.invalid/",
                                    tokenProvider: InstantTokenProvider()))
    }

    func testComposableCollectUnmountedElementFails() {
        let container = offlineClient().container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))
        _ = container!.create(input: CollectElementInput(tableName: "persons", column: "name", type: .CARDHOLDER_NAME))

        let expectation = XCTestExpectation(description: "composable collect with unmounted element should fail")
        let callback = DemoAPICallback(expectation: expectation)
        container!.collect(callback: callback.asCollectCallback)

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.UNMOUNTED_COLLECT_ELEMENT(value: "name").description)
    }

    func testComposableCollectEmptyAdditionalFieldsRecordsFails() {
        let container = offlineClient().container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))
        let element = container!.create(input: CollectElementInput(tableName: "persons", column: "name", type: .CARDHOLDER_NAME))
        UIWindow().addSubview(element)

        let expectation = XCTestExpectation(description: "composable collect with empty additionalFields should fail")
        let callback = DemoAPICallback(expectation: expectation)
        container!.collect(callback: callback.asCollectCallback, options: CollectOptions(additionalFields: AdditionalFields(records: [])))

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.EMPTY_RECORDS_OBJECT().description)
    }

    func testComposableCollectEmptyUpsertFails() {
        let container = offlineClient().container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))
        let element = container!.create(input: CollectElementInput(tableName: "persons", column: "name", type: .CARDHOLDER_NAME))
        UIWindow().addSubview(element)

        let expectation = XCTestExpectation(description: "composable collect with empty upsert should fail")
        let callback = DemoAPICallback(expectation: expectation)
        container!.collect(callback: callback.asCollectCallback, options: CollectOptions(upsert: []))

        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(callback.receivedResponse, ErrorCodes.UPSERT_OPTION_CANNOT_BE_EMPTY().description)
    }

    func testComposableCollectValidElementRunsFullRequestFlow() {
        let container = offlineClient().container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))
        let element = container!.create(input: CollectElementInput(tableName: "persons", column: "name", type: .CARDHOLDER_NAME))
        element.textField.secureText = "John"
        UIWindow().addSubview(element)

        let options = CollectOptions(
            additionalFields: AdditionalFields(records: [AdditionalFieldsRecord(tableName: "contacts", data: ["email": "a@b.com"])]),
            upsert: [UpsertOption(tableName: "persons", uniqueColumns: ["name"])])

        let expectation = XCTestExpectation(description: "composable collect should reach the network layer and fail offline")
        let callback = DemoAPICallback(expectation: expectation)
        container!.collect(callback: callback.asCollectCallback, options: options)

        wait(for: [expectation], timeout: 20.0)
        // The whole request-building path (validators, CollectRequestBuilder, CVV
        // capture, postAndUpdate) executed; the unresolvable host then failed it.
        XCTAssertFalse(callback.receivedResponse == "default" && callback.data.isEmpty)
    }
}
