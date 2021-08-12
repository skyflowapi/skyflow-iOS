//
//  File.swift
//  
//
//  Created by Santhosh Kamal Murthy Yennam on 10/08/21.
//

import Foundation

class RevealApiCallback : SkyflowCallback {
    
    var apiClient: APIClient
    var callback: SkyflowCallback
    var connectionUrl : URL
    var requestBody : String
    var method : String
    
    internal init(callback: SkyflowCallback, apiClient: APIClient, connectionUrl: URL, requestBody: String!, method: String){
        self.apiClient = apiClient
        self.callback = callback
        self.connectionUrl = connectionUrl
        self.requestBody = requestBody
        self.method = method
    }
    
    internal func onSuccess(_ token: String) {
        print("onsuccess method for revealapiCallback")
        var request = URLRequest(url: connectionUrl)
        print(connectionUrl)
        request.httpMethod = method
        request.addValue("application/json; utf-8", forHTTPHeaderField: "Content-Type");
        request.addValue("application/json", forHTTPHeaderField: "Accept");
        request.addValue("Bearer " + token, forHTTPHeaderField: "Authorization");
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: request) { data, response, error in
            if(error != nil){
                self.callback.onFailure(error!)
                return
            }
            let dataString = String(decoding: data!, as: UTF8.self)
            self.callback.onSuccess(dataString)
                
        }
        task.resume()
    }
    internal func onFailure(_ error: Error) {
        self.callback.onFailure(error)
    }
}


