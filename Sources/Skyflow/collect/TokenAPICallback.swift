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
    var contextOptions: ContextOptions

    internal init(callback: Callback, apiClient: APIClient, contextOptions: ContextOptions) {
        self.callback = callback
        self.apiClient = apiClient
        self.contextOptions = contextOptions
    }

    internal func onSuccess(_ responseBody: Any) {
        if responseBody is String {
            self.apiClient.token = responseBody as! String
            Log.log(logLevel: .INFO, message: .BEARER_TOKEN_RECEIVED, contextOptions: self.contextOptions)
            callback.onSuccess(responseBody as! String)
        } else {
            self.callback.onFailure(ErrorCodes.INVALID_BEARER_TOKEN_FORMAT().errorObject)
        }
    }

    internal func onFailure(_ error: Error) {
        self.callback.onFailure(error)
    }
}
