/*
 * Copyright (c) 2022 Skyflow
 */

import Foundation

internal class TokenAPICallback: Callback {
    var callback: Callback
    var apiClient: APIClient
    var contextOptions: ContextOptions

    internal init(callback: Callback, apiClient: APIClient, contextOptions: ContextOptions) {
        self.callback = callback
        self.apiClient = apiClient
        self.contextOptions = contextOptions
    }

    internal func onSuccess(_ responseBody: Any) {
        if responseBody is String {
            Log.info(message: .BEARER_TOKEN_RECEIVED, contextOptions: self.contextOptions)
            let previousToken = self.apiClient.token
            self.apiClient.token = responseBody as! String

            if !self.apiClient.isTokenValid() {
                self.apiClient.token = previousToken
                callback.onFailure(ErrorCodes.INVALID_BEARER_TOKEN_FORMAT().getErrorObject(contextOptions: contextOptions))
            } else {
                callback.onSuccess(responseBody as! String)
            }
        } else {
            self.callback.onFailure(ErrorCodes.INVALID_BEARER_TOKEN_FORMAT().getErrorObject(contextOptions: contextOptions))
        }
    }

    internal func onFailure(_ error: Any) {
        self.callback.onFailure(error)
    }
}
