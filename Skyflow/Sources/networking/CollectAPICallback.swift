/*
 * Copyright (c) 2022 Skyflow
*/

// Callback used while API callback for Collect the elements

import Foundation

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
        let insertRecords = records["records"] as? [[String: Any]]
        let hasInsert = insertRecords?.isEmpty == false
        let updateRecords = records["update"] as? [String: Any]
        let hasUpdate = updateRecords?.isEmpty == false
        let group = DispatchGroup()
        var insertResponse: [String: Any]? = nil
        var updateResponses: [[String: Any]] = []
        var requestError: [Any]? = []
        var requestUpdateError: [Any]? = []

        let callbackQueue = DispatchQueue.main

        if !hasInsert && !hasUpdate {
            self.callback.onSuccess([:])
            return
        }

        if hasInsert {
            group.enter()
            guard let url = URL(string: self.apiClient.legacyVaultURL + self.apiClient.vaultID) else {
                self.callback.onFailure(ErrorCodes.INVALID_URL().getErrorObject(contextOptions: self.contextOptions))
                return
            }
            do {
                let (request, session) = try self.getRequestSession(url: url)
                let task = session.dataTask(with: request) { data, response, error in
                    defer {
                        group.leave()
                    }
                    do {
                        let response = try self.processResponse(data: data, response: response, error: error)
                        if response["error"] != nil {
                            requestError?.append(response)
                        } else {
                            insertResponse = response
                        }
                    } catch {
                        requestError?.append(error)
                    }
                }
                task.resume()
            } catch let error {
                requestError?.append(error)
            }
        }
        if hasUpdate, let updateArray = records["update"] as? [String: [String: Any]] {
            for (_, updateRecord) in updateArray {
                group.enter()
                guard let table = updateRecord["table"] as? String, let skyflowID = updateRecord["skyflowID"] as? String else {
                    group.leave()
                    continue
                }
                let urlString = self.apiClient.legacyVaultURL + self.apiClient.vaultID + "/" + table + "/" + skyflowID
                guard let url = URL(string: urlString) else {
                    group.leave()
                    requestError?.append(ErrorCodes.INVALID_URL().getErrorObject(contextOptions: self.contextOptions))
                    continue
                }
                do {
                    var singleUpdateRecords: [String: Any] = [:]
                    singleUpdateRecords["fields"] = updateRecord["fields"]
                    singleUpdateRecords["table"] = table
                    singleUpdateRecords["skyflowID"] = skyflowID
                    let (request, session) = try self.getRequestSessionForUpdate(url: url, updateRecords: singleUpdateRecords)
                    let task = session.dataTask(with: request) { data, response, error in
                        defer {
                            group.leave() }
                        do {
                            let response = try self.processUpdateResponse(data: data, response: response, error: error, table: table)
                            if response["error"] != nil {
                                requestUpdateError?.append(response)
                            } else {
                                updateResponses.append(response)
                            }
                        } catch {
                            requestUpdateError?.append(error)
                        }
                    }
                    task.resume()
                } catch let error {
                    group.leave()
                    requestUpdateError?.append(error)
                    continue
                }
            }
        }

        group.notify(queue: callbackQueue) {
            var mergedRecords: [Any] = []
            var mergedErrors: [Any] = []
            if let insert = insertResponse?["records"] as? [Any] {
                mergedRecords.append(contentsOf: insert)
            }
            for updateResp in updateResponses {
                if let update = updateResp["records"] as? [Any] {
                    mergedRecords.append(contentsOf: update)
                }
            }
            if requestUpdateError != nil {
                mergedErrors.append(contentsOf: requestUpdateError!)
            }
            if requestError != nil {
                mergedErrors.append(contentsOf: requestError!)
            }
            if mergedRecords.isEmpty {
                self.callback.onFailure(["errors": mergedErrors])
            } else if mergedErrors.isEmpty {
                self.callback.onSuccess(["records": mergedRecords])
            } else {
                self.callback.onFailure(["records": mergedRecords, "errors": mergedErrors])
            }
        }
    }

    internal func onFailure(_ error: Any) {
        self.callback.onFailure(error)
    }

    internal func buildFieldsDict(dict: [String: Any]) -> [String: Any] {
        return ConversionHelpers.buildFieldsDict(dict: dict)
    }
    internal func getRequestSession(url: URL) throws -> (URLRequest, URLSession) {
        let jsonString = FetchMetrices().buildMetadataHeaderValue(sdkName: self.contextOptions.sdkName)
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
    
    // Helper for single update request
    private func getRequestSessionForUpdate(url: URL, updateRecords: [String: Any]) throws -> (URLRequest, URLSession) {
        let jsonString = FetchMetrices().buildMetadataHeaderValue(sdkName: self.contextOptions.sdkName)
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        do {
            let data = try JSONSerialization.data(withJSONObject: self.apiClient.constructUpdateRequestBody(records: updateRecords, options: options))
            request.httpBody = data
        }
        request.setValue(("Bearer " + self.apiClient.token), forHTTPHeaderField: "Authorization")
        request.setValue(jsonString, forHTTPHeaderField: "sky-metadata")
        return (request, URLSession(configuration: .default))
    }
    
    func processUpdateResponse(data: Data?, response: URLResponse?, error: Error?, table: String) throws -> [String: Any] {
        if error != nil || response == nil {
            return ["error": ["message": (error)?.localizedDescription ?? "Unknown error"]]
        }
        if let httpResponse = response as? HTTPURLResponse {
            let range = 400...599
            if range ~= httpResponse.statusCode {
                var description = "Update call failed with the following status code" + String(httpResponse.statusCode)
                if let safeData = data {
                    do {
                        let desc = try JSONSerialization.jsonObject(with: safeData, options: .allowFragments) as! [String: Any]
                        let error = desc["error"] as? [String: Any]
                        if let error = error, let message = error["message"] as? String {
                            description = message
                        }
                        if let requestId = httpResponse.allHeaderFields["x-request-id"] {
                            description += " - request-id: \(requestId)"
                        }
                    } catch {
                        return ["error": ["message": String(data: safeData, encoding: .utf8) ?? "Unknown error", "code": httpResponse.statusCode]]
                    }
                }
                return ["error": ["message": description, "code": httpResponse.statusCode]]
            }
        }
        guard let safeData = data else {
            return ["records": []]
        }
        let jsonData = try JSONSerialization.jsonObject(with: safeData, options: .allowFragments) as! [String: Any]
        var record: [String: Any] = [:]
        var id =  ""
        if let skyflowId = jsonData["skyflow_id"] as? String{
            id = skyflowId
        } else {
            id = String(describing: jsonData["skyflow_id"] ?? "")
        }

        if self.options.tokens {
            let fieldsDict = jsonData["tokens"] as? [String: Any]
            if fieldsDict != nil {
                let fieldsData = try JSONSerialization.data(withJSONObject: fieldsDict!)
                let fieldsObj = try JSONSerialization.jsonObject(with: fieldsData, options: .allowFragments)
                var fieldsSkyflowId: [String: Any] = self.buildFieldsDict(dict: fieldsObj as? [String: Any] ?? [:])
                fieldsSkyflowId["skyflow_id"] = id
                record["fields"] = fieldsSkyflowId
            }
        } else {
            record["skyflow_id"] = id
        }
        record["table"] = table
        return ["records": [record]]
    }
    
    func processResponse(data: Data?, response: URLResponse?, error: Error?) throws -> [String: Any] {
        if error != nil || response == nil {
            return ["error": ["message": (error)?.localizedDescription ?? "Unknown error"]]
        }

        if let httpResponse = response as? HTTPURLResponse {
            let range = 400...599
            if range ~= httpResponse.statusCode {
                var description = "Insert call failed with the following status code " + String(httpResponse.statusCode)
                if let safeData = data {
                    do {
                        let errorResponse = try JSONSerialization.jsonObject(with: safeData, options: .allowFragments) as! [String: Any]
                        if let errorDetails = errorResponse["error"] as? [String: Any],
                           let message = errorDetails["message"] as? String {
                            description = message
                        }
                        if let requestId = httpResponse.allHeaderFields["x-request-id"] {
                            description += " - request-id: \(requestId)"
                        }
                    } catch {
                        return ["error": ["message": String(data: safeData, encoding: .utf8) ?? "Unknown error", "code": httpResponse.statusCode]]
                    }
                }
                return ["error": ["message": description, "code": httpResponse.statusCode]]
            }
        }

        guard let safeData = data else {
            return [:]
        }
        
        return try getCollectResponseBody(data: safeData)
                
    }
    
    // Reads the skyflow_id out of the batch response entry at responseIndex, guarding every
    // step of the shape (top-level dict, "records" array, first element, "skyflow_id" key) and
    // the array bounds - a malformed or short response yields nil instead of crashing.
    private func skyflowId(in receivedResponseArray: [Any], atResponseIndex responseIndex: Int) -> Any? {
        guard responseIndex >= 0, responseIndex < receivedResponseArray.count,
              let recordsWrapper = receivedResponseArray[responseIndex] as? [String: Any],
              let recordsArray = recordsWrapper["records"] as? [Any],
              let firstRecord = recordsArray.first as? [String: Any] else {
            return nil
        }
        return firstRecord["skyflow_id"]
    }

    func getCollectResponseBody(data: Data) throws -> [String: Any]{
        let originalString = String(decoding: data, as: UTF8.self)
        let changedData = Data(originalString.utf8)
        guard let jsonData = try JSONSerialization.jsonObject(with: changedData, options: .allowFragments) as? [String: Any],
              let receivedResponseArray = jsonData["responses"] as? [Any],
              let inputRecords = self.records["records"] as? [Any] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Malformed collect response"])
        }
        var responseEntries: [Any] = []

        let length = inputRecords.count
        for (index, _) in inputRecords.enumerated() {
            var tempEntry: [String: Any] = [:]
            tempEntry["table"] = (inputRecords[index] as? [String: Any])?["table"]
            if self.options.tokens {
                let responseIndex = length + index
                if responseIndex < receivedResponseArray.count,
                   let fieldsDict = (receivedResponseArray[responseIndex] as? [String: Any])?["fields"] {
                    let fieldsData = try JSONSerialization.data(withJSONObject: fieldsDict)
                    let fieldsObj = try JSONSerialization.jsonObject(with: fieldsData, options: .allowFragments)
                    tempEntry["fields"] = self.buildFieldsDict(dict: fieldsObj as? [String: Any] ?? [:])
                    tempEntry[keyPath: "fields.skyflow_id"] = skyflowId(in: receivedResponseArray, atResponseIndex: index)
                }
            } else {
                tempEntry["skyflow_id"] = skyflowId(in: receivedResponseArray, atResponseIndex: index)
            }
            responseEntries.append(tempEntry)
        }

        return ["records": responseEntries]

    }
}
