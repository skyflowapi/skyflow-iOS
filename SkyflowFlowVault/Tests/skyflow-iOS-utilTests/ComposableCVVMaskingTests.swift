/*
 * Copyright (c) 2022 Skyflow
*/

// End-to-end CVV mocking through a real ComposableContainer.collect() call, network-mocked via
// MockURLProtocol. skyflow_iOS_cvvMockTests.swift already covers CVVTokenReplacer/CVVCaptureMap/
// CVVMaskingCallback exhaustively at the unit level, and source reading already confirmed
// CVVMaskingCallback is wired into ComposableContainerOperations.swift's collect() path - but
// until now nothing exercised that wiring through an actual container.collect() call for the
// composable path specifically (the collect-container path is equally untested this way, but
// this file scopes to composable per the gap identified in this session).

import XCTest
@testable import SkyflowFlowVault
@testable import SkyflowCore

// DemoTokenProvider (used by most other tests in this bundle) returns "dummy_token", which is
// not a well-formed JWT - APIClient.isTokenValid() correctly rejects it, so any test that needs
// to get past bearer-token validation into a real (mocked) network call needs a provider that
// returns something shaped like a real token instead.
private class WellFormedJWTTokenProvider: TokenProvider {
    func getBearerToken(_ apiCallback: Callback) {
        let payload = try! JSONSerialization.data(withJSONObject: ["exp": 4079020800]) // year 2099
        let token = "header." + payload.base64EncodedString() + ".signature"
        apiCallback.onSuccess(token)
    }
}

final class ComposableCVVMaskingTests: XCTestCase {

    private func mockRequestHandler(cvvColumn: String, realToken: String, skyflowID: String, tableName: String) -> (URLRequest) throws -> (HTTPURLResponse, Data) {
        return { request in
            let body: [String: Any] = [
                "records": [[
                    "skyflowID": skyflowID,
                    "tableName": tableName,
                    "tokens": [cvvColumn: [["token": realToken, "tokenGroupName": "deterministic"]]],
                    "httpCode": 200
                ]]
            ]
            let data = try! JSONSerialization.data(withJSONObject: body)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.1", headerFields: nil)!
            return (response, data)
        }
    }

    private func withMockedNetwork(_ handler: @escaping (URLRequest) throws -> (HTTPURLResponse, Data), _ body: () -> Void) {
        let mockConfiguration = URLSessionConfiguration.ephemeral
        mockConfiguration.protocolClasses = [MockURLProtocol.self]
        let original = FlowVaultCollectAPICallback.urlSessionConfiguration
        FlowVaultCollectAPICallback.urlSessionConfiguration = mockConfiguration
        MockURLProtocol.requestHandler = handler
        body()
        FlowVaultCollectAPICallback.urlSessionConfiguration = original
    }

    func testComposableCollectMasksThreeDigitCVVToken() throws {
        let client = Client(Configuration(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: WellFormedJWTTokenProvider()))
        let container = client.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))

        let cvvInput = CollectElementInput(tableName: "persons", column: "cvv", type: .CVV)
        let cvvElement = container!.create(input: cvvInput, options: CollectElementOptions(returnMockValue: true))
        cvvElement.actualValue = "123"

        let view = try container!.getComposableView()
        let window = UIWindow()
        window.addSubview(view)

        let expectation = XCTestExpectation(description: "Composable collect masks CVV")
        let callback = DemoAPICallback(expectation: expectation)

        withMockedNetwork(mockRequestHandler(cvvColumn: "cvv", realToken: "real-vault-token-should-not-leak", skyflowID: "id1", tableName: "persons")) {
            container?.collect(callback: callback.asCollectCallback)
        }

        wait(for: [expectation], timeout: 10.0)

        guard let collectResponse = callback.collectResponse else {
            XCTFail("Expected a CollectResponse, got: receivedResponse=\(callback.receivedResponse) data=\(callback.data)")
            return
        }
        let cvvToken = collectResponse.records.first?.tokens?["cvv"]?.first?.token
        XCTAssertEqual(cvvToken, "817")
        XCTAssertNotEqual(cvvToken, "real-vault-token-should-not-leak")
    }

    func testComposableCollectMasksFourDigitCVVToken() throws {
        let client = Client(Configuration(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: WellFormedJWTTokenProvider()))
        let container = client.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))

        let cvvInput = CollectElementInput(tableName: "persons", column: "cvv", type: .CVV)
        let cvvElement = container!.create(input: cvvInput, options: CollectElementOptions(returnMockValue: true))
        cvvElement.actualValue = "1234"

        let view = try container!.getComposableView()
        let window = UIWindow()
        window.addSubview(view)

        let expectation = XCTestExpectation(description: "Composable collect masks 4-digit CVV")
        let callback = DemoAPICallback(expectation: expectation)

        withMockedNetwork(mockRequestHandler(cvvColumn: "cvv", realToken: "real-vault-token-should-not-leak", skyflowID: "id1", tableName: "persons")) {
            container?.collect(callback: callback.asCollectCallback)
        }

        wait(for: [expectation], timeout: 10.0)

        guard let collectResponse = callback.collectResponse else {
            XCTFail("Expected a CollectResponse, got: receivedResponse=\(callback.receivedResponse) data=\(callback.data)")
            return
        }
        XCTAssertEqual(collectResponse.records.first?.tokens?["cvv"]?.first?.token, "8173")
    }

    // Confirms the returnMockValue gate holds end-to-end through composable collect(), not just
    // in the CVVTokenReplacer unit tests: the real vault token must pass through unmasked when
    // the element never opted in.
    func testComposableCollectLeavesCVVUnmaskedWhenReturnMockValueFalse() throws {
        let client = Client(Configuration(vaultID: "vault", vaultURL: "https://example.org/", tokenProvider: WellFormedJWTTokenProvider()))
        let container = client.container(type: ContainerType.COMPOSABLE, options: ContainerOptions(layout: [1]))

        let cvvInput = CollectElementInput(tableName: "persons", column: "cvv", type: .CVV)
        // Default CollectElementOptions() - returnMockValue defaults to false.
        let cvvElement = container!.create(input: cvvInput, options: CollectElementOptions())
        cvvElement.actualValue = "123"

        let view = try container!.getComposableView()
        let window = UIWindow()
        window.addSubview(view)

        let expectation = XCTestExpectation(description: "Composable collect leaves CVV unmasked")
        let callback = DemoAPICallback(expectation: expectation)

        withMockedNetwork(mockRequestHandler(cvvColumn: "cvv", realToken: "real-vault-token", skyflowID: "id1", tableName: "persons")) {
            container?.collect(callback: callback.asCollectCallback)
        }

        wait(for: [expectation], timeout: 10.0)

        guard let collectResponse = callback.collectResponse else {
            XCTFail("Expected a CollectResponse, got: receivedResponse=\(callback.receivedResponse) data=\(callback.data)")
            return
        }
        XCTAssertEqual(collectResponse.records.first?.tokens?["cvv"]?.first?.token, "real-vault-token")
    }
}
