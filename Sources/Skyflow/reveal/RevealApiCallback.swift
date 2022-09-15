/*
 * Copyright (c) 2022 Skyflow
 */

//
//  File.swift
//  
//
//  Created by Santhosh Kamal Murthy Yennam on 10/08/21.
//

import Foundation

class RevealAPICallback: Callback {
    var apiClient: APIClient
    var callback: Callback
    var connectionUrl: String
    var records: [RevealRequestRecord]
    var contextOptions: ContextOptions
    
    
    internal init(callback: Callback, apiClient: APIClient, connectionUrl: String,
                  records: [RevealRequestRecord], contextOptions: ContextOptions) {
        self.apiClient = apiClient
        self.callback = callback
        self.connectionUrl = connectionUrl
        self.records = records
        self.contextOptions = contextOptions
    }
    
    internal func onSuccess(_ token: Any) {
        var list_success: [RevealSuccessRecord] = []
        var list_error: [RevealErrorRecord] = []
        let revealRequestGroup = DispatchGroup()
        
        var isSuccess = true
        var errorObject: Error!
        var errorCode: ErrorCodes?
        
        if URL(string: (connectionUrl + "/detokenize")) == nil {
            errorCode = .INVALID_URL()
            self.callRevealOnFailure(callback: self.callback, errorObject: errorCode!.getErrorObject(contextOptions: self.contextOptions))
            return
        }
        
        for record in records {
            var (request, session) = getRequestSession()
            revealRequestGroup.enter()
            
            
            do {
                request.httpBody = try getRevealRequestBody(record: record)
            } catch let error {
                self.callback.onFailure(error)
                return
            }
            
            let task = session.dataTask(with: request) { data, response, error in
                defer {
                    revealRequestGroup.leave()
                }
                
                do {
                    let (success, failure) = try self.processResponse(record: record, data: data, response: response, error: error)
                    
                    if success != nil {
                        list_success.append(success!)
                    }
                    if failure != nil {
                        list_error.append(failure!)
                    }
                } catch {
                    isSuccess = false
                    errorObject = error
                }
            }
            
            task.resume()
        }
        
        revealRequestGroup.notify(queue: .main) {
            self.handleCallbacks(success: list_success, failure: list_error, isSuccess: isSuccess, errorObject: errorObject)
        }
    }
    internal func onFailure(_ error: Any) {
        if error is Error {
            callRevealOnFailure(callback: self.callback, errorObject: error as! Error)
        } else {
            self.callback.onFailure(error)
        }
    }
    
    private func callRevealOnFailure(callback: Callback, errorObject: Error) {
        let result = ["errors": [["error": errorObject]]]
        callback.onFailure(result)
    }
    
    internal func getRequestSession() -> (URLRequest, URLSession){
        let url = URL(string: (connectionUrl + "/detokenize"))
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.setValue("application/json; utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(("Bearer " + self.apiClient.token), forHTTPHeaderField: "Authorization")
        
        return (request, URLSession(configuration: .default))
    }
    
    internal func getRevealRequestBody(record: RevealRequestRecord) throws -> Data {
        let bodyObject: [String: Any] =
            [
                "detokenizationParameters": [
                    [
                        "token": record.token
                    ]
                ]
            ]
        return try JSONSerialization.data(withJSONObject: bodyObject)
    }
    
    internal func processResponse(record: RevealRequestRecord, data: Data?, response: URLResponse?, error: Error?) throws -> (RevealSuccessRecord?, RevealErrorRecord?){
        
        if error != nil || response == nil {
            throw error!
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            let range = 400...599
            if range ~= httpResponse.statusCode {
                var description = "Reveal call failed with the following status code" + String(httpResponse.statusCode)
                
                if let safeData = data {
                    let desc = try JSONSerialization.jsonObject(with: safeData, options: .allowFragments) as! [String: Any]
                    let error = desc["error"] as! [String: Any]
                    description = error["message"] as! String
                    if let requestId = httpResponse.allHeaderFields["x-request-id"] {
                        description += " - request-id: \(requestId)"
                    }
                }
                let error: NSError = ErrorCodes.APIError(code: httpResponse.statusCode, message: description).getErrorObject(contextOptions: self.contextOptions)
                let errorRecord = RevealErrorRecord(id: record.token, error: error )
                return (nil, errorRecord)
            }
        }
        
        if let safeData = data {
            let jsonData = try JSONSerialization.jsonObject(with: safeData, options: .allowFragments) as! [String: Any]
            let receivedResponseArray: [Any] = (jsonData[keyPath: "records"] as! [Any])
            let records: [String: Any] = receivedResponseArray[0] as! [String: Any]
            let successRecord = RevealSuccessRecord(token_id: records["token"] as! String, value: records["value"] as! String)
            
            return (successRecord, nil)
        }
        
        return (nil, nil)
    }
    
    func handleCallbacks(success: [RevealSuccessRecord], failure: [RevealErrorRecord], isSuccess: Bool, errorObject: Error!) {
        var records: [Any] = []
        for record in success {
            var entry: [String: Any] = [:]
            entry["token"] = record.token_id
            entry["value"] = record.value
            records.append(entry)
        }
        var errors: [Any] = []
        for record in failure {
            var entry: [String: Any] = [:]
            entry["token"] = record.id
            entry["error"] = record.error
            errors.append(entry)
        }
        var modifiedResponse: [String: Any] = [:]
        if records.count != 0 {
            modifiedResponse["records"] = records
        }
        if errors.count != 0 {
            modifiedResponse["errors"] = errors
        }
        
        if isSuccess {
            if errors.isEmpty {
                self.callback.onSuccess(modifiedResponse)
            } else {
                self.callback.onFailure(modifiedResponse)
            }
        } else {
            self.callRevealOnFailure(callback: self.callback, errorObject: errorObject)
        }
    }
}
