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
    var connectionUrl : String
    var requestBody : String
    var method : String
    var records : [RevealRequestRecord]
    
    internal init(callback: SkyflowCallback, apiClient: APIClient, connectionUrl: String,
                  requestBody: String!, method: String,records : [RevealRequestRecord]){
        self.apiClient = apiClient
        self.callback = callback
        self.connectionUrl = connectionUrl
        self.requestBody = requestBody
        self.method = method
        self.records = records
    }
    
    internal func onSuccess(_ token: String) {
        var list_success : [RevealSuccessRecord] = []
        var list_error : [RevealErrorRecord] = []
        var count = 0
        for record in records
        {
            let url = URL(string: (connectionUrl+"/tokens?token_ids="+record.token+"&redaction="+record.redaction))
            var request = URLRequest(url: url!)
            request.httpMethod = method
            request.addValue("application/json; utf-8", forHTTPHeaderField: "Content-Type");
            request.addValue("application/json", forHTTPHeaderField: "Accept");
            request.addValue("Bearer " + token, forHTTPHeaderField: "Authorization");
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: request) { data, response, error in
                count += 1
                if(error != nil || response == nil){
                    self.callback.onFailure(error!)
                    return
                }
                if let httpResponse = response as? HTTPURLResponse{
                    let range = 400...599
                    if range ~= httpResponse.statusCode {
                        var desc = "Reveal call failed with the following status code" + String(httpResponse.statusCode)
                        
                        if let safeData = data{
                            desc = String(decoding: safeData, as: UTF8.self)
                        }
                        var error:[String:String] = [:]
                        error["code"] = String(httpResponse.statusCode)
                        error["description"] = desc
                        let errorRecord = RevealErrorRecord(id: record.token, error: error )
                        list_error.append(errorRecord)
                        return
                    }
                }
                
                if let safeData = data
                {
                    do
                    {
                        let jsonData = try JSONSerialization.jsonObject(with: safeData, options: .allowFragments) as! [String: Any]
                        let receivedResponseArray : [Any]  = (jsonData[keyPath: "records"] as! [Any])
                        let records : [String:Any]  = receivedResponseArray[0] as! [String : Any]
                        list_success.append(RevealSuccessRecord(token_id: records["token_id"] as! String, fields:records["fields"] as! [String : String]))
                        }
                        catch let error {
                            self.callback.onFailure(error)
                            print(error)
                                }
                }
                if(count == self.records.count)
                {
                    var response = "{\"records\": ["
                    for record in list_success
                    {
                        response = response + "{"
                        response = response + "id:" + record.token_id+","
                        for field in record.fields
                        {
                            response = response + field.key+":"+field.value+","
                        }
                        response = response+"},"
                    }
                    var x = response.prefix(response.count-1)
                    response = x + "],"
                    response = response + " \"errors\": ["
                    for record in list_error
                    {
                        response = response + "{"
                        response = response + "id:" + record.id+","
                        response = response + " error : ["
                        for field in record.error
                        {
                            response = response + field.key+":"+field.value+","
                        }
                        response = response + "]"
                        response = response+"},"
                    }
                    x = response.prefix(response.count-1)
                    response = x + "]}"
                    self.callback.onSuccess(response)
                }
                               
                }

            task.resume()
            
        }
    }
    internal func onFailure(_ error: Error) {
        self.callback.onFailure(error)
    }
}

