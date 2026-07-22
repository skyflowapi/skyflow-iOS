/*
 * Copyright (c) 2022 Skyflow
*/

// Callback used while API callback for Collect the elements (FlowDB v2)

import Foundation
import UIKit

internal class FlowVaultInsertAPICallback: Callback {
    var apiClient: APIClient
    var records: [String: Any]
    var callback: Callback
    var options: FlowVaultICOptions
    var contextOptions: ContextOptions

    internal init(callback: Callback, apiClient: APIClient, records: [String: Any], options: FlowVaultICOptions, contextOptions: ContextOptions) {
        self.records = records
        self.apiClient = apiClient
        self.callback = callback
        self.options = options
        self.contextOptions = contextOptions
    }
    internal func onSuccess(_ responseBody: Any) {
        let insertRecords = records["records"] as? [[String: Any]] ?? []
        let updatesByTable = self.groupUpdatesByTable(records["update"] as? [String: Any] ?? [:])
        let hasInsert = !insertRecords.isEmpty
        let hasUpdate = !updatesByTable.isEmpty

        if !hasInsert && !hasUpdate {
            self.callback.onSuccess(["records": [], "errors": []])
            return
        }

        // No update records: preserve the original single-call insert behavior exactly
        // (including throwing a full-request-level failure straight to onFailure).
        if !hasUpdate {
            guard let url = URL(string: self.apiClient.vaultURL + "v2/records/insert") else {
                self.callback.onFailure(ErrorCodes.INVALID_URL().getErrorObject(contextOptions: self.contextOptions))
                return
            }
            do {
                let (request, session) = try self.getRequestSession(url: url)
                let task = session.dataTask(with: request) { data, response, error in
                    do {
                        let response = try self.processResponse(data: data, response: response, error: error)
                        let errors = response["errors"] as? [[String: Any]] ?? []
                        if errors.isEmpty {
                            self.callback.onSuccess(response)
                        } else {
                            self.callback.onFailure(response)
                        }
                    } catch {
                        self.callback.onFailure(error)
                    }
                }
                task.resume()
            } catch let error {
                self.callback.onFailure(error)
            }
            return
        }

        guard URL(string: self.apiClient.vaultURL + "v2/records/insert") != nil else {
            self.callback.onFailure(ErrorCodes.INVALID_URL().getErrorObject(contextOptions: self.contextOptions))
            return
        }

        let group = DispatchGroup()
        var mergedRecords: [[String: Any]] = []
        var mergedErrors: [[String: Any]] = []

        if hasInsert {
            group.enter()
            let url = URL(string: self.apiClient.vaultURL + "v2/records/insert")!
            do {
                let (request, session) = try self.getRequestSession(url: url)
                let task = session.dataTask(with: request) { data, response, error in
                    defer { group.leave() }
                    do {
                        let response = try self.processResponse(data: data, response: response, error: error)
                        mergedRecords.append(contentsOf: response["records"] as? [[String: Any]] ?? [])
                        mergedErrors.append(contentsOf: response["errors"] as? [[String: Any]] ?? [])
                    } catch {
                        mergedErrors.append(["error": error.localizedDescription])
                    }
                }
                task.resume()
            } catch let error {
                mergedErrors.append(["error": error.localizedDescription])
                group.leave()
            }
        }

        for (tableName, tableRecords) in updatesByTable {
            group.enter()
            let url = URL(string: self.apiClient.vaultURL + "v2/records/update")!
            do {
                let (request, session) = try self.getUpdateRequestSession(url: url, tableName: tableName, records: tableRecords)
                let task = session.dataTask(with: request) { data, response, error in
                    defer { group.leave() }
                    do {
                        let response = try self.processResponse(data: data, response: response, error: error)
                        mergedRecords.append(contentsOf: response["records"] as? [[String: Any]] ?? [])
                        mergedErrors.append(contentsOf: response["errors"] as? [[String: Any]] ?? [])
                    } catch {
                        mergedErrors.append(["error": error.localizedDescription])
                    }
                }
                task.resume()
            } catch let error {
                mergedErrors.append(["error": error.localizedDescription])
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let response: [String: Any] = ["records": mergedRecords, "errors": mergedErrors]
            if mergedErrors.isEmpty {
                self.callback.onSuccess(response)
            } else {
                self.callback.onFailure(response)
            }
        }
    }

    internal func onFailure(_ error: Any) {
        self.callback.onFailure(error)
    }

    internal func groupUpdatesByTable(_ updateDict: [String: Any]) -> [String: [[String: Any]]] {
        var updatesByTable: [String: [[String: Any]]] = [:]
        for (skyflowID, value) in updateDict {
            guard let entry = value as? [String: Any],
                  let tableName = entry["table"] as? String,
                  let fields = entry["fields"] as? [String: Any] else { continue }
            let record: [String: Any] = ["skyflowID": skyflowID, "data": fields]
            updatesByTable[tableName, default: []].append(record)
        }
        return updatesByTable
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
            let data = try JSONSerialization.data(withJSONObject: FlowVaultInsertRequestBody.createRequestBody(vaultID: self.apiClient.vaultID, records: self.records, options: options))
            request.httpBody = data
        }

        request.setValue(("Bearer " + self.apiClient.token), forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(jsonString, forHTTPHeaderField: "sky-metadata")

        return (request, URLSession(configuration: .default))

    }

    internal func getUpdateRequestSession(url: URL, tableName: String, records: [[String: Any]]) throws -> (URLRequest, URLSession) {
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
            let data = try JSONSerialization.data(withJSONObject: FlowVaultUpdateRequestBody.createRequestBody(vaultID: self.apiClient.vaultID, tableName: tableName, records: records))
            request.httpBody = data
        }

        request.setValue(("Bearer " + self.apiClient.token), forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
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
                // FlowDB returns a non-2xx status when every record in the batch fails,
                // but the body still has the same {"records": [...]} shape as a success/partial
                // response (each record carrying its own error/httpCode) - parse it as such.
                if let safeData = data,
                   let jsonObject = try? JSONSerialization.jsonObject(with: safeData, options: .allowFragments) as? [String: Any],
                   jsonObject["records"] != nil {
                    return try getCollectResponseBody(data: safeData)
                }
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
            return ["records": [], "errors": []]
        }

        return try getCollectResponseBody(data: safeData)

    }

    func getCollectResponseBody(data: Data) throws -> [String: Any]{
        let jsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
        var successRecords: [[String: Any]] = []
        var errorRecords: [[String: Any]] = []

        let responseRecords = jsonData["records"] as? [[String: Any]] ?? []
        for entry in responseRecords {
            if let error = entry["error"] as? String {
                var errorEntry: [String: Any] = ["error": error]
                if let skyflowID = entry["skyflowID"] { errorEntry["skyflowID"] = skyflowID }
                if let tableName = entry["tableName"] { errorEntry["tableName"] = tableName }
                if let httpCode = entry["httpCode"] { errorEntry["httpCode"] = httpCode }
                errorRecords.append(errorEntry)
            } else {
                var successEntry: [String: Any] = [:]
                if let skyflowID = entry["skyflowID"] { successEntry["skyflowID"] = skyflowID }
                if let tableName = entry["tableName"] { successEntry["tableName"] = tableName }
                if let httpCode = entry["httpCode"] { successEntry["httpCode"] = httpCode }
                if let data = entry["data"] as? [String: Any] { successEntry["data"] = self.buildFieldsDict(dict: data) }
                if let hashedData = entry["hashedData"] as? [String: Any] { successEntry["hashedData"] = self.buildFieldsDict(dict: hashedData) }
                if self.options.tokens, let tokens = entry["tokens"] as? [String: Any] {
                    successEntry["tokens"] = self.buildFieldsDict(dict: tokens)
                }
                successRecords.append(successEntry)
            }
        }

        return ["records": successRecords, "errors": errorRecords]
    }
}
