//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 21/09/21.
//

import Foundation

class RevealByIDAPICallback: Callback {
    var apiClient: APIClient
    var callback: Callback
    var connectionUrl: String
    var records: [GetByIdRecord]
    var contextOptions: ContextOptions


    internal init(callback: Callback, apiClient: APIClient, connectionUrl: String,
                  records: [GetByIdRecord], contextOptions: ContextOptions) {
        self.apiClient = apiClient
        self.callback = callback
        self.connectionUrl = connectionUrl
        self.records = records
        self.contextOptions = contextOptions
    }

    internal func onSuccess(_ token: Any) {
        let getByIdRequestGroup = DispatchGroup()
        var outputArray: [[String: Any]] = []
        var errorArray: [[String: Any]] = []
        var isSuccess = true
        var errorObject: Error!

        if URL(string: (connectionUrl + "/")) == nil {
            self.callRevealOnFailure(callback: callback, errorObject: ErrorCodes.INVALID_URL().getErrorObject(contextOptions: self.contextOptions))
            return
        }

        for record in records {
            var urlComponents = URLComponents(string: (connectionUrl + "/" + record.table))

            urlComponents?.queryItems = []

            for id in record.ids {
                urlComponents?.queryItems?.append(URLQueryItem(name: "skyflow_ids", value: id))
            }

            urlComponents?.queryItems?.append(URLQueryItem(name: "redaction", value: record.redaction))


            if urlComponents?.url?.absoluteURL == nil {
                var errorEntryDict: [String: Any] = [
                    "ids": record.ids
                ]
                let errorDict: [String: Any] = [
                    "code": 400,
                    "description": "Table name or id is invalid"
                ]
                errorEntryDict["error"] = errorDict
                errorArray.append(errorEntryDict)
                continue
            }
            getByIdRequestGroup.enter()
            var request = URLRequest(url: (urlComponents?.url!.absoluteURL)!)
            request.httpMethod = "GET"
            request.addValue("application/json; utf-8", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue(("Bearer " + self.apiClient.token), forHTTPHeaderField: "Authorization")
            let session = URLSession(configuration: .default)
            let task = session.dataTask(with: request) { data, response, error in
                defer {
                    getByIdRequestGroup.leave()
                }
                if error != nil || response == nil {
                    isSuccess = false
                    errorObject = error!
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    let range = 400...599
                    if range ~= httpResponse.statusCode {
                        var description = "getById call failed with the following status code" + String(httpResponse.statusCode)

                        if let safeData = data {
                            do {
                                let desc = try JSONSerialization.jsonObject(with: safeData, options: .allowFragments) as! [String: Any]
                                if let error = desc["error"] as? [String: Any], let message = error["message"] as? String {
                                    description = message
                                    var errorEntryDict: [String: Any] = [
                                        "ids": record.ids
                                    ]
                                    let errorDict: NSError = ErrorCodes.APIError(code: httpResponse.statusCode, message: description).errorObject
                                    errorEntryDict["error"] = errorDict
                                    errorArray.append(errorEntryDict)
                                }
                            } catch let error {
                                isSuccess = false
                                errorObject = error
                            }
                        }
                        return
                    }
                }

                if let safeData = data {
                    do {
                        let originalString = String(decoding: safeData, as: UTF8.self)
                        let replacedString = originalString.replacingOccurrences(of: "\"skyflow_id\":", with: "\"id\":")
                        let changedData = Data(replacedString.utf8)
                        let jsonData = try JSONSerialization.jsonObject(with: changedData, options: .allowFragments) as! [String: Any]
                        if let jsonDataArray = jsonData["records"] as? [[String: Any]] {
                            for entry in jsonDataArray {
                                var entryDict = self.buildFieldsDict(dict: entry)
                                entryDict["table"] = record.table
                                outputArray.append(entryDict)
                            }
                        }
                    } catch let error {
                        isSuccess = false
                        errorObject = error
                    }
                }
            }

            task.resume()
        }
        getByIdRequestGroup.notify(queue: .main) {
            var records: [String: Any] = [:]
            if outputArray.count != 0 {
                records["records"] = outputArray
            }
            if errorArray.count != 0 {
                records["errors"] = errorArray
            }
            if isSuccess {
                if errorArray.isEmpty {
                    self.callback.onSuccess(records)
                } else {
                    self.callback.onFailure(records)
                }
            } else {
                self.callRevealOnFailure(callback: self.callback, errorObject: errorObject!)
            }
        }
    }
    internal func onFailure(_ error: Any) {
        if error is Error{
            callRevealOnFailure(callback: self.callback, errorObject: error as! Error)
        }
        else {
            self.callback.onFailure(error)
        }
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
    
    private func callRevealOnFailure(callback: Callback, errorObject: Error) {
        let result = ["errors": errorObject]
        callback.onFailure(result)
    }
}
