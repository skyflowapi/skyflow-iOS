/*
 * Copyright (c) 2022 Skyflow
*/

// Implementation of callback for Reveal api (FlowDB v2)

import Foundation

class FlowVaultRevealAPICallback: Callback {
    var apiClient: APIClient
    var callback: Callback
    var connectionUrl: String
    var records: [RevealRequestRecord]
    var tokenGroupRedactions: [TokenGroupRedaction]?
    var contextOptions: ContextOptions


    internal init(callback: Callback, apiClient: APIClient, connectionUrl: String,
                  records: [RevealRequestRecord], tokenGroupRedactions: [TokenGroupRedaction]? = nil, contextOptions: ContextOptions) {
        self.apiClient = apiClient
        self.callback = callback
        self.connectionUrl = connectionUrl
        self.records = records
        self.tokenGroupRedactions = tokenGroupRedactions
        self.contextOptions = contextOptions
    }

    internal func onSuccess(_ token: Any) {
        guard let url = URL(string: connectionUrl) else {
            let errorCode = ErrorCodes.INVALID_URL()
            self.callRevealOnFailure(callback: self.callback, errorObject: errorCode.getErrorObject(contextOptions: self.contextOptions))
            return
        }

        do {
            let (request, session) = try getRequestSession(url: url)
            let task = session.dataTask(with: request) { data, response, error in
                do {
                    let response = try self.processResponse(data: data, response: response, error: error)
                    self.callback.onSuccess(response)
                } catch {
                    self.callRevealOnFailure(callback: self.callback, errorObject: error)
                }
            }
            task.resume()
        } catch let error {
            self.callRevealOnFailure(callback: self.callback, errorObject: error)
        }
    }

    internal func onFailure(_ error: Any) {
        if let error = error as? Error {
            callRevealOnFailure(callback: self.callback, errorObject: error)
        } else {
            self.callback.onFailure(error)
        }
    }

    private func callRevealOnFailure(callback: Callback, errorObject: Error) {
        callback.onFailure(ConversionHelpers.wrapRevealFailure(errorObject: errorObject))
    }

    internal func getRequestSession(url: URL) throws -> (URLRequest, URLSession) {
        let jsonString = FetchMetrices().buildMetadataHeaderValue(sdkName: self.contextOptions.sdkName)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            let data = try JSONSerialization.data(withJSONObject: RevealRequestBuilder.createDetokenizeRequestBody(vaultID: self.apiClient.vaultID, records: records, tokenGroupRedactions: tokenGroupRedactions))
            request.httpBody = data
        }

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(("Bearer " + self.apiClient.token), forHTTPHeaderField: "Authorization")
        request.setValue(jsonString, forHTTPHeaderField: "sky-metadata")

        return (request, URLSession(configuration: .default))
    }

    func processResponse(data: Data?, response: URLResponse?, error: Error?) throws -> [String: Any] {
        if error != nil || response == nil {
            throw error ?? ErrorCodes.APIError(code: 0, message: "Unknown error").getErrorObject(contextOptions: self.contextOptions)
        }

        if let httpResponse = response as? HTTPURLResponse {
            let range = 400...599
            if range ~= httpResponse.statusCode {
                // FlowDB returns a non-2xx status when every token in the batch fails to
                // detokenize, but the body still has the same {"response": [...]} shape as a
                // success/partial response (each entry carrying its own error/httpCode) - parse
                // it as such instead of collapsing into a generic top-level error.
                if let safeData = data,
                   let jsonObject = try? JSONSerialization.jsonObject(with: safeData, options: .allowFragments) as? [String: Any],
                   jsonObject["response"] != nil {
                    return try getDetokenizeResponseBody(data: safeData)
                }
                var description = "Detokenize call failed with the following status code " + String(httpResponse.statusCode)
                if let safeData = data {
                    guard let errorResponse = try? JSONSerialization.jsonObject(with: safeData, options: .allowFragments) as? [String: Any] else {
                        throw ErrorCodes.APIError(code: httpResponse.statusCode, message: String(data: safeData, encoding: .utf8) ?? "Unknown error").getErrorObject(contextOptions: self.contextOptions)
                    }
                    if let errorDetails = errorResponse["error"] as? [String: Any],
                       let message = errorDetails["message"] as? String {
                        description = message
                    }
                    if let requestId = httpResponse.allHeaderFields["x-request-id"] {
                        description += " - request-id: \(requestId)"
                    }
                }
                throw ErrorCodes.APIError(code: httpResponse.statusCode, message: description).getErrorObject(contextOptions: self.contextOptions)
            }
        }

        guard let safeData = data else {
            return ["records": []]
        }

        return try getDetokenizeResponseBody(data: safeData)
    }

    func getDetokenizeResponseBody(data: Data) throws -> [String: Any] {
        let jsonData = (try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]) ?? [:]
        var records: [[String: Any]] = []

        let responseRecords = jsonData["response"] as? [[String: Any]] ?? []
        for entry in responseRecords {
            if let error = entry["error"] as? String {
                var errorEntry: [String: Any] = ["error": error]
                if let token = entry["token"] { errorEntry["token"] = token }
                if let httpCode = entry["httpCode"] { errorEntry["httpCode"] = httpCode }
                records.append(errorEntry)
            } else {
                var successEntry: [String: Any] = [:]
                if let token = entry["token"] { successEntry["token"] = token }
                if let value = entry["value"] { successEntry["value"] = value }
                if let tokenGroupName = entry["tokenGroupName"] { successEntry["tokenGroupName"] = tokenGroupName }
                if let httpCode = entry["httpCode"] { successEntry["httpCode"] = httpCode }
                if let metadata = entry["metadata"] as? [String: Any] { successEntry["metadata"] = metadata }
                records.append(successEntry)
            }
        }

        return ["records": records]
    }
}
