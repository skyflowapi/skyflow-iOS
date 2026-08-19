/*
 * Copyright (c) 2022 Skyflow
*/

// Callback used while API callback for Collect the elements

import Foundation

internal class InsertAPICallback: Callback {
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
        guard let url = URL(string: self.apiClient.legacyVaultURL + self.apiClient.vaultID) else {
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
    
    func processResponse(data: Data?, response: URLResponse?, error: Error?) throws -> [String: Any] {
        if error != nil || response == nil {
            throw error ?? NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
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
