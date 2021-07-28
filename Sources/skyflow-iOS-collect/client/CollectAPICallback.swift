//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 23/07/21.
//

import Foundation

internal class CollectAPICallback: APICallback {
    
    var apiClient: APIClient
    var records: [[String:Any]]
    var callback: APICallback
    
    internal init(callback: APICallback, apiClient: APIClient, records: [[String:Any]]){
        self.records = records
        self.apiClient = apiClient
        self.callback = callback
    }
    
    internal func onSuccess(_ responseBody: String) {
        if let url = URL(string: self.apiClient.workspaceURL + self.apiClient.vaultId) {
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            do {
                let data = try JSONSerialization.data(withJSONObject: ["records" : self.apiClient.constructBatchRequestBody(records: self.records)])
                request.httpBody = data
            } catch let error {
                print(error.localizedDescription)
            }
            
            request.addValue("Bearer " + (self.apiClient.token), forHTTPHeaderField: "Authorization")
            
            let session = URLSession(configuration: .default)
            
            let task = session.dataTask(with: request) { data, response, error in
                if(error != nil){
                    self.callback.onFailure(error!)
                    return
                }
                
                if let safeData = data {
                    let dataString = String(data: safeData, encoding: .utf8)
                    self.callback.onSuccess(dataString!)
                }
            }
            task.resume()
        }
    }
    
    internal func onFailure(_ error: Error) {
        self.callback.onFailure(error)
    }
}
