/*
 * Copyright (c) 2022 Skyflow
*/

// Tests for the shared bearer-token lifecycle in SkyflowCore: APIClient.isTokenValid(),
// APIClient.getAccessToken() and TokenAPICallback. This layer is contract-agnostic and
// used identically by both SDKs.

import XCTest
@testable import SkyflowFlowVault
@testable import SkyflowCore

final class TokenLifecycleTests: XCTestCase {

    // A TokenProvider that fails the test if it's ever invoked, for asserting that a
    // still-valid cached token is reused without refreshing.
    private final class FailIfCalledTokenProvider: TokenProvider {
        func getBearerToken(_ apiCallback: Callback) {
            XCTFail("token provider should not be called while the cached token is still valid")
        }
    }

    private final class RecordingCallback: Callback {
        var successValue: Any?
        var failureValue: Any?

        func onSuccess(_ responseBody: Any) {
            successValue = responseBody
        }

        func onFailure(_ error: Any) {
            failureValue = error
        }
    }

    // Builds a JWT-shaped "header.payload" token whose payload is valid, decodable JSON
    // carrying the given "exp" claim -- the only shape isTokenValid() can evaluate without
    // hitting one of its internal force-casts.
    private func jwt(exp: Int) -> String {
        let payload = try! JSONSerialization.data(withJSONObject: ["exp": exp])
        return "header.\(payload.base64EncodedString())"
    }

    // MARK: - APIClient.isTokenValid()

    func testIsTokenValidFalseForEmptyToken() {
        let apiClient = APIClient(vaultID: "", vaultURL: "", tokenProvider: DemoTokenProvider())
        XCTAssertFalse(apiClient.isTokenValid())
    }

    func testIsTokenValidFalseForTokenWithoutPayloadSeparator() {
        let apiClient = APIClient(vaultID: "", vaultURL: "", tokenProvider: DemoTokenProvider())
        apiClient.token = "no-dot-separator"
        XCTAssertFalse(apiClient.isTokenValid())
    }

    func testIsTokenValidFalseForNonJSONPayload() {
        let apiClient = APIClient(vaultID: "", vaultURL: "", tokenProvider: DemoTokenProvider())
        let payload = Data("not json {{{".utf8).base64EncodedString()
        apiClient.token = "header.\(payload)"
        XCTAssertFalse(apiClient.isTokenValid())
    }

    func testIsTokenValidFalseForExpiredToken() {
        let apiClient = APIClient(vaultID: "", vaultURL: "", tokenProvider: DemoTokenProvider())
        apiClient.token = jwt(exp: 1) // 1970-01-01T00:00:01Z, long expired
        XCTAssertFalse(apiClient.isTokenValid())
    }

    func testIsTokenValidTrueForFutureExpiryToken() {
        let apiClient = APIClient(vaultID: "", vaultURL: "", tokenProvider: DemoTokenProvider())
        apiClient.token = jwt(exp: 9_999_999_999) // year 2286
        XCTAssertTrue(apiClient.isTokenValid())
    }

    // MARK: - APIClient.getAccessToken()

    func testGetAccessTokenReusesStillValidTokenWithoutCallingProvider() {
        let apiClient = APIClient(vaultID: "", vaultURL: "", tokenProvider: FailIfCalledTokenProvider())
        let validToken = jwt(exp: 9_999_999_999)
        apiClient.token = validToken

        let callback = RecordingCallback()
        apiClient.getAccessToken(callback: callback, contextOptions: ContextOptions())

        XCTAssertEqual(callback.successValue as? String, validToken)
        XCTAssertNil(callback.failureValue)
    }

    func testGetAccessTokenRefreshesWhenTokenMissing() {
        let apiClient = APIClient(vaultID: "", vaultURL: "", tokenProvider: DemoTokenProvider())
        XCTAssertEqual(apiClient.token, "")

        let callback = RecordingCallback()
        apiClient.getAccessToken(callback: callback, contextOptions: ContextOptions())

        // DemoTokenProvider hands back the raw string "dummy_token", which isn't a
        // well-formed bearer token, so TokenAPICallback should reject it.
        XCTAssertNil(callback.successValue)
        XCTAssertNotNil(callback.failureValue)
        XCTAssertEqual(apiClient.token, "") // reverted, not left as the malformed value
    }

    // MARK: - TokenAPICallback

    func testTokenAPICallbackAcceptsWellFormedToken() {
        let apiClient = APIClient(vaultID: "", vaultURL: "", tokenProvider: DemoTokenProvider())
        let callback = RecordingCallback()
        let tokenApiCallback = TokenAPICallback(callback: callback, apiClient: apiClient, contextOptions: ContextOptions())

        let newToken = jwt(exp: 9_999_999_999)
        tokenApiCallback.onSuccess(newToken)

        XCTAssertEqual(callback.successValue as? String, newToken)
        XCTAssertNil(callback.failureValue)
        XCTAssertEqual(apiClient.token, newToken)
    }

    func testTokenAPICallbackRevertsAndFailsOnMalformedStringToken() {
        let apiClient = APIClient(vaultID: "", vaultURL: "", tokenProvider: DemoTokenProvider())
        apiClient.token = jwt(exp: 9_999_999_999)
        let previousToken = apiClient.token

        let callback = RecordingCallback()
        let tokenApiCallback = TokenAPICallback(callback: callback, apiClient: apiClient, contextOptions: ContextOptions())

        tokenApiCallback.onSuccess("not-a-jwt")

        XCTAssertNil(callback.successValue)
        let error = (callback.failureValue as? NSError)
        XCTAssertEqual(error?.localizedDescription, ErrorCodes.INVALID_BEARER_TOKEN_FORMAT().description)
        XCTAssertEqual(apiClient.token, previousToken) // reverted rather than left malformed
    }

    func testTokenAPICallbackFailsOnNonStringResponseBody() {
        let apiClient = APIClient(vaultID: "", vaultURL: "", tokenProvider: DemoTokenProvider())
        let callback = RecordingCallback()
        let tokenApiCallback = TokenAPICallback(callback: callback, apiClient: apiClient, contextOptions: ContextOptions())

        tokenApiCallback.onSuccess(["unexpected": "shape"])

        XCTAssertNil(callback.successValue)
        let error = (callback.failureValue as? NSError)
        XCTAssertEqual(error?.localizedDescription, ErrorCodes.INVALID_BEARER_TOKEN_FORMAT().description)
    }

    func testTokenAPICallbackPassesThroughProviderFailure() {
        let apiClient = APIClient(vaultID: "", vaultURL: "", tokenProvider: DemoTokenProvider())
        let callback = RecordingCallback()
        let tokenApiCallback = TokenAPICallback(callback: callback, apiClient: apiClient, contextOptions: ContextOptions())

        let providerError = NSError(domain: "TokenProviderDomain", code: 42, userInfo: [NSLocalizedDescriptionKey: "provider blew up"])
        tokenApiCallback.onFailure(providerError)

        XCTAssertNil(callback.successValue)
        XCTAssertTrue((callback.failureValue as? NSError) === providerError)
    }
}
