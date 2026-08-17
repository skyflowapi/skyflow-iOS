/*
 * Copyright (c) 2022 Skyflow
*/


// Contract-agnostic API client: bearer token lifecycle and shared vault operations.
// Contract-specific operations (insert/collect/detokenize) live in the SDK targets
// as extensions on this class.

import Foundation

package class APIClient {
    package var vaultID: String
    // Normalized base vault URL (always ends with "/"); SDK targets append their
    // contract-specific paths (v1/vaults/... or v2/...).
    package var vaultURL: String
    package var tokenProvider: TokenProvider
    package var token: String = ""

    package init(vaultID: String, vaultURL: String, tokenProvider: TokenProvider) {
        self.vaultID = vaultID
        self.vaultURL = vaultURL
        self.tokenProvider = tokenProvider
    }

    package func isTokenValid() -> Bool {
        if token == "" {
            return false
        }

        let components = token.components(separatedBy: ".")

        if components.count < 2 {
            return false
        }

        var payload64 = components[1]

        while payload64.count % 4 != 0 {
            payload64 += "="
        }

        let payloadData = Data(base64Encoded: payload64,
                               options: .ignoreUnknownCharacters)!

        do {
            let json = try JSONSerialization.jsonObject(with: payloadData, options: []) as! [String: Any]
            let exp = json["exp"] as! Int
            let expDate = Date(timeIntervalSince1970: TimeInterval(exp))

            return expDate.compare(Date()) == .orderedDescending
        } catch {
            return false
        }
    }

    package func getAccessToken(callback: Callback, contextOptions: ContextOptions) {
        if !isTokenValid() {
            let tokenApiCallback = TokenAPICallback(callback: callback, apiClient: self, contextOptions: contextOptions)
            tokenProvider.getBearerToken(tokenApiCallback)
        } else {
            callback.onSuccess(token)
        }
    }

}
