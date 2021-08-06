//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 23/07/21.
//

import Foundation

internal class CollectAPICallback: SkyflowCallback {
    
    var apiClient: APIClient
    var records: [String:Any]
    var callback: SkyflowCallback
    var options: InsertOptions
    
    internal init(callback: SkyflowCallback, apiClient: APIClient, records: [String:Any], options: InsertOptions){
        self.records = records
        self.apiClient = apiClient
        self.callback = callback
        self.options = options
    }
    
    internal func onSuccess(_ responseBody: String) {
        if let url = URL(string: self.apiClient.vaultURL + self.apiClient.vaultId) {
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            do {
                let data = try JSONSerialization.data(withJSONObject:  self.apiClient.constructBatchRequestBody(records: self.records, options: options))
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
                    let originalString = String(decoding: safeData, as: UTF8.self)
                    let replacedString = originalString.replacingOccurrences(of: "\"*\":", with: "\"skyflow_id\":")
                    let changedData = Data(replacedString.utf8)
                    do {
                        let jsonData = try JSONSerialization.jsonObject(with: changedData, options: .allowFragments) as! [String: Any]
                        
                        var responseEntries:[Any] = []

                        let receivedResponseArray = (jsonData[keyPath: "responses"] as! [Any])

                        let inputRecords = self.records["records"] as! [Any]
                        
                        let length = inputRecords.count
                        for (index, _) in inputRecords.enumerated(){
                            var tempEntry:[String:Any] = [:]
                            tempEntry["table"] = (inputRecords[index] as! [String:Any])["tableName"]
                            if(self.options.tokens){
                                tempEntry["fields"] = (receivedResponseArray[length + index] as! [String:Any])["fields"] ?? nil
                            }
                            else{
                                tempEntry["skyflow_id"] = (((receivedResponseArray[index] as! [String:Any])["records"] as! [Any])[0] as! [String:Any])["skyflow_id"]
                            }
                            responseEntries.append(tempEntry)
                        }
                        
                        let dataString = String(data: try JSONSerialization.data(withJSONObject: ["records": responseEntries]), encoding: .utf8)
                        
                        self.callback.onSuccess(dataString!)
                                                
                    } catch let error {
                        self.callback.onFailure(error)
                        print(error)
                    }
                }
            }
            task.resume()
        }
    }
    
    internal func onFailure(_ error: Error) {
        self.callback.onFailure(error)
    }
}
