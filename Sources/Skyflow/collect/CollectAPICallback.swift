/*
 * Copyright (c) 2022 Skyflow
*/

// Callback used while API callback for Collect the elements

import Foundation
import UIKit

internal class CollectAPICallback: Callback {
    var apiClient: APIClient
    var records: [String: Any]
    var callback: Callback
    var options: ICOptions
    var contextOptions: ContextOptions

    internal init(callback: Callback, apiClient: APIClient, records: [String: Any], options: ICOptions, contextOptions: ContextOptions) {
        self.records = records
        self.apiClient = apiClient
        self.callback = callback
        self.options = options
        self.contextOptions = contextOptions
    }
    internal func onSuccess(_ responseBody: Any) {
        guard let url = URL(string: self.apiClient.vaultURL + self.apiClient.vaultID) else {
            self.callback.onFailure(ErrorCodes.INVALID_URL().getErrorObject(contextOptions: self.contextOptions))
            return
        }
        
        do {
            let (request, session) = try self.getRequestSession(url: url)
        
        
            let task = session.dataTask(with: request) { data, response, error in
                do {
                    let response = try self.processResponse(data: data, response: response, error: error)
                    self.callback.onSuccess(response)
                } catch {
                    self.callback.onFailure(error)
                }
            }
            task.resume()
        } catch let error {
            self.callback.onFailure(error)
            return
        }
    }

    internal func onFailure(_ error: Any) {
        self.callback.onFailure(error)
    }

    internal func buildFieldsDict(dict: [String: Any]) -> [String: Any] {
        var temp: [String: Any] = [:]
        for (key, val) in dict {
            if let v = val as? [String: Any] {
                temp[key] = buildFieldsDict(dict: v)
            } else {
                temp[key] = val
            }
        }
        return temp
    }
    internal func getRequestSession(url: URL) throws -> (URLRequest, URLSession) {
        var jsonString = ""

        do {
           let deviceDetails = FetchMetrices().getMetrices()
            let jsonData = try JSONSerialization.data(withJSONObject: deviceDetails, options: [])
            jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            jsonString = ""
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            let data = try JSONSerialization.data(withJSONObject: self.apiClient.constructBatchRequestBody(records: self.records, options: options))
            request.httpBody = data
        }
        
        request.setValue(("Bearer " + self.apiClient.token), forHTTPHeaderField: "Authorization")
        request.setValue(jsonString, forHTTPHeaderField: "sky-metadata")

        return (request, URLSession(configuration: .default))

    }
    
    func processResponse(data: Data?, response: URLResponse?, error: Error?) throws -> [String: Any] {
        if error != nil || response == nil {
            throw error!
        }

        if let httpResponse = response as? HTTPURLResponse {
            let range = 400...599
            if range ~= httpResponse.statusCode {
                var description = "Insert call failed with the following status code" + String(httpResponse.statusCode)
                var errorObject: Error = ErrorCodes.APIError(code: httpResponse.statusCode, message: description).getErrorObject(contextOptions: self.contextOptions)

                if let safeData = data {
                    do {
                        let desc = try JSONSerialization.jsonObject(with: safeData, options: .allowFragments) as! [String: Any]
                        let error = desc["error"] as! [String: Any]
                        description = error["message"] as! String
                        if let requestId = httpResponse.allHeaderFields["x-request-id"] {
                            description += " - request-id: \(requestId)"
                        }
                        errorObject = ErrorCodes.APIError(code: httpResponse.statusCode, message: description).getErrorObject(contextOptions: self.contextOptions)
                    } catch {
                        errorObject = ErrorCodes.APIError(code: httpResponse.statusCode, message: String(data: safeData, encoding: .utf8)!).getErrorObject(contextOptions: self.contextOptions)
                    }
                }
                throw errorObject
            }
        }

        guard let safeData = data else {
            return [:]
        }
        
        return try getCollectResponseBody(data: safeData)
                
    }
    
    func getCollectResponseBody(data: Data) throws -> [String: Any]{
        let originalString = String(decoding: data, as: UTF8.self)
        let changedData = Data(originalString.utf8)
        let jsonData = try JSONSerialization.jsonObject(with: changedData, options: .allowFragments) as! [String: Any]
        var responseEntries: [Any] = []

        let receivedResponseArray = (jsonData[keyPath: "responses"] as! [Any])

        let inputRecords = self.records["records"] as! [Any]

        let length = inputRecords.count
        for (index, _) in inputRecords.enumerated() {
            var tempEntry: [String: Any] = [:]
            tempEntry["table"] = (inputRecords[index] as! [String: Any])["table"]
            if self.options.tokens {
                let fieldsDict = (receivedResponseArray[length + index] as! [String: Any])["fields"]
                if fieldsDict != nil {
                    let fieldsData = try JSONSerialization.data(withJSONObject: fieldsDict!)
                    let fieldsObj = try JSONSerialization.jsonObject(with: fieldsData, options: .allowFragments)
                    tempEntry["fields"] = self.buildFieldsDict(dict: fieldsObj as? [String: Any] ?? [:])
                    tempEntry[keyPath: "fields.skyflow_id"] = (((receivedResponseArray[index] as! [String: Any])["records"] as! [Any])[0] as! [String: Any])["skyflow_id"]
                }
            } else {
                tempEntry["skyflow_id"] = (((receivedResponseArray[index] as! [String: Any])["records"] as! [Any])[0] as! [String: Any])["skyflow_id"]
            }
            responseEntries.append(tempEntry)
        }

        return ["records": responseEntries]

    }
}
