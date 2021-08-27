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
    
    internal init(callback: Callback, apiClient: APIClient){
        self.callback = callback
        self.apiClient = apiClient
    }
    
    internal func onSuccess(_ responseBody: String) {
        self.apiClient.token = responseBody
        callback.onSuccess(responseBody)
    }
    
    internal func onFailure(_ error: Error) {
        self.callback.onFailure(error)
    }
}
