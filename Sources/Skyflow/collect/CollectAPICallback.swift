//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 23/07/21.
//

import Foundation

internal class CollectAPICallback: Callback {
    var apiClient: APIClient
    var records: [String: Any]
    var callback: Callback
    var options: ICOptions

    internal init(callback: Callback, apiClient: APIClient, records: [String: Any], options: ICOptions) {
        self.records = records
        self.apiClient = apiClient
        self.callback = callback
        self.options = options
    }

    internal func onSuccess(_ responseBody: Any) {
        if let url = URL(string: self.apiClient.vaultURL + self.apiClient.vaultID) {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            do {
                let data = try JSONSerialization.data(withJSONObject: self.apiClient.constructBatchRequestBody(records: self.records, options: options))
                request.httpBody = data
            } catch let error {
                self.callback.onFailure(error)
                return
            }

            request.addValue(("Bearer " + self.apiClient.token), forHTTPHeaderField: "Authorization")

            let session = URLSession(configuration: .default)

            let task = session.dataTask(with: request) { data, response, error in
                if error != nil || response == nil {
                    self.callback.onFailure(error!)
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    let range = 400...599
                    if range ~= httpResponse.statusCode {
                        var description = "Insert call failed with the following status code" + String(httpResponse.statusCode)
                        var errorObject: Error = ErrorCodes.APIError(code: httpResponse.statusCode, message: description).errorObject

                        if let safeData = data {
                            do {
                                let desc = try JSONSerialization.jsonObject(with: safeData, options: .allowFragments) as! [String: Any]
                                let error = desc["error"] as! [String: Any]
                                description = error["message"] as! String
                                errorObject = ErrorCodes.APIError(code: httpResponse.statusCode, message: description).errorObject
                            } catch let error {
                                errorObject = error
                            }
                        }
                        self.callback.onFailure(errorObject as Any)
                        return
                    }
                }

                if let safeData = data {
                    let originalString = String(decoding: safeData, as: UTF8.self)
                    let replacedString = originalString.replacingOccurrences(of: "\"*\":", with: "\"skyflow_id\":")
                    let changedData = Data(replacedString.utf8)
                    do {
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
                                }
                            } else {
                                tempEntry["skyflow_id"] = (((receivedResponseArray[index] as! [String: Any])["records"] as! [Any])[0] as! [String: Any])["skyflow_id"]
                            }
                            responseEntries.append(tempEntry)
                        }

                        self.callback.onSuccess(["records": responseEntries])
                    } catch let error {
                        self.callback.onFailure(error)
                    }
                }
            }
            task.resume()
        } else {
            self.callback.onFailure(ErrorCodes.INVALID_URL().errorObject)
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
}
