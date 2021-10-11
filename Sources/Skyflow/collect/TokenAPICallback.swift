//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 23/07/21.
//

import Foundation

internal class TokenAPICallback: Callback {
    var callback: Callback
    var apiClient: APIClient

    internal init(callback: Callback, apiClient: APIClient) {
        self.callback = callback
        self.apiClient = apiClient
    }

    internal func onSuccess(_ responseBody: Any) {
        if responseBody is String {
            self.apiClient.token = responseBody as! String
            callback.onSuccess(responseBody as! String)
        } else {
            self.callback.onFailure(ErrorCodes.INVALID_BEARER_TOKEN_FORMAT().errorObject)
        }
    }

    internal func onFailure(_ error: Any) {
        self.callback.onFailure(error)
    }
}
