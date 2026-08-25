/*
 * Copyright (c) 2022 Skyflow
*/

// Callback used while API callback for Collect the elements (FlowDB v2)

import Foundation

internal class FlowVaultCollectAPICallback: Callback {
    // Overridable only for tests (e.g. injecting a URLProtocol mock via protocolClasses) - global
    // URLProtocol.registerClass(_:) isn't reliably consulted for manually-created URLSession
    // instances in every environment, so tests need a real seam here instead.
    internal static var urlSessionConfiguration: URLSessionConfiguration = .default

    var apiClient: APIClient
    var records: [String: Any]
    var callback: Callback
    var upsert: [UpsertOptions]?
    var contextOptions: ContextOptions

    internal init(callback: Callback, apiClient: APIClient, records: [String: Any], upsert: [UpsertOptions]? = nil, contextOptions: ContextOptions) {
        self.records = records
        self.apiClient = apiClient
        self.callback = callback
        self.upsert = upsert
        self.contextOptions = contextOptions
    }

    internal func onSuccess(_ responseBody: Any) {
        let insertRecords = records["records"] as? [[String: Any]] ?? []
        let updateRecords = self.flattenUpdates(records["update"] as? [String: Any] ?? [:])
        let hasInsert = !insertRecords.isEmpty
        let hasUpdate = !updateRecords.isEmpty

        if !hasInsert && !hasUpdate {
            self.callback.onSuccess(["records": []])
            return
        }

        // No update records: preserve the original single-call insert behavior exactly
        // (including passing a full-request-level failure straight through, unwrapped).
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
                        if response["error"] != nil {
                            self.callback.onFailure(response)
                            return
                        }
                        self.callback.onSuccess(["records": response["records"] as? [[String: Any]] ?? []])
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

        let group = DispatchGroup()
        // The insert and update sub-requests each build their OWN URLSession (see
        // getRequestSession/getUpdateRequestSession), and a session created without an explicit
        // delegateQueue makes its own serial queue - so these two completion handlers run on two
        // different queues and CAN fire concurrently. Sharing one accumulator between them would be
        // a data race on a non-thread-safe Swift Array (corrupting it, then crashing later when the
        // merged records are read back). So each side gets its own pair: every accumulator below has
        // exactly one writer, and they're only read from group.notify, which DispatchGroup
        // guarantees happens-after both leave() calls. No locking required.
        var insertResponseRecords: [[String: Any]] = []
        var insertResponseErrors: [[String: Any]] = []
        var updateResponseRecords: [[String: Any]] = []
        var updateResponseErrors: [[String: Any]] = []

        if hasInsert {
            group.enter()
            if let url = URL(string: self.apiClient.vaultURL + "v2/records/insert") {
                do {
                    let (request, session) = try self.getRequestSession(url: url)
                    let task = session.dataTask(with: request) { data, response, error in
                        defer { group.leave() }
                        do {
                            let response = try self.processResponse(data: data, response: response, error: error)
                            if response["error"] != nil {
                                insertResponseErrors.append(response)
                            } else {
                                insertResponseRecords.append(contentsOf: response["records"] as? [[String: Any]] ?? [])
                            }
                        } catch {
                            // as NSError: any Swift Error bridges to NSError, giving SkyflowError.wrap
                            // (its "errors" array branch checks `nested["error"] as? NSError`) a shape
                            // it can actually unwrap into a real domain/code/message, instead of falling
                            // through to a generic code:0 error with a raw Swift-interpolated string.
                            insertResponseErrors.append(["error": error as NSError])
                        }
                    }
                    task.resume()
                } catch let error {
                    insertResponseErrors.append(["error": error as NSError])
                    group.leave()
                }
            } else {
                insertResponseErrors.append(["error": ErrorCodes.INVALID_URL().getErrorObject(contextOptions: self.contextOptions)])
                group.leave()
            }
        }

        if hasUpdate {
            group.enter()
            if let url = URL(string: self.apiClient.vaultURL + "v2/records/update") {
                do {
                    let (request, session) = try self.getUpdateRequestSession(url: url, records: updateRecords)
                    let task = session.dataTask(with: request) { data, response, error in
                        defer { group.leave() }
                        do {
                            let response = try self.processResponse(data: data, response: response, error: error)
                            if response["error"] != nil {
                                updateResponseErrors.append(response)
                            } else {
                                updateResponseRecords.append(contentsOf: response["records"] as? [[String: Any]] ?? [])
                            }
                        } catch {
                            // See the matching insert-side catch above for why `as NSError`
                            // (not .localizedDescription) is required here.
                            updateResponseErrors.append(["error": error as NSError])
                        }
                    }
                    task.resume()
                } catch let error {
                    updateResponseErrors.append(["error": error as NSError])
                    group.leave()
                }
            } else {
                updateResponseErrors.append(["error": ErrorCodes.INVALID_URL().getErrorObject(contextOptions: self.contextOptions)])
                group.leave()
            }
        }

        group.notify(queue: .main) {
            // Insert results first, then update results - a deterministic order, rather than
            // "whichever request happened to finish first" as a shared accumulator would give.
            let mergedRecords = insertResponseRecords + updateResponseRecords
            let mergedErrors = insertResponseErrors + updateResponseErrors
            if mergedErrors.isEmpty {
                self.callback.onSuccess(["records": mergedRecords])
            } else {
                self.callback.onFailure(["records": mergedRecords, "errors": mergedErrors])
            }
        }
    }

    internal func onFailure(_ error: Any) {
        self.callback.onFailure(error)
    }

    internal func flattenUpdates(_ updateDict: [String: Any]) -> [[String: Any]] {
        var updateRecords: [[String: Any]] = []
        for (skyflowID, value) in updateDict {
            guard let entry = value as? [String: Any],
                  let tableName = entry["table"] as? String,
                  let fields = entry["fields"] as? [String: Any] else { continue }
            updateRecords.append(["skyflowID": skyflowID, "tableName": tableName, "data": fields])
        }
        return updateRecords
    }

    internal func getRequestSession(url: URL) throws -> (URLRequest, URLSession) {
        let jsonString = FetchMetrices().buildMetadataHeaderValue(sdkName: self.contextOptions.sdkName)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            let data = try JSONSerialization.data(withJSONObject: CollectRequestBuilder.createInsertRequestBody(vaultID: self.apiClient.vaultID, records: self.records, upsert: self.upsert))
            request.httpBody = data
        }

        request.setValue(("Bearer " + self.apiClient.token), forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(jsonString, forHTTPHeaderField: "sky-metadata")

        return (request, URLSession(configuration: Self.urlSessionConfiguration))

    }

    internal func getUpdateRequestSession(url: URL, records: [[String: Any]]) throws -> (URLRequest, URLSession) {
        let jsonString = FetchMetrices().buildMetadataHeaderValue(sdkName: self.contextOptions.sdkName)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            let data = try JSONSerialization.data(withJSONObject: CollectRequestBuilder.createUpdateRequestBody(vaultID: self.apiClient.vaultID, records: records))
            request.httpBody = data
        }

        request.setValue(("Bearer " + self.apiClient.token), forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(jsonString, forHTTPHeaderField: "sky-metadata")

        return (request, URLSession(configuration: Self.urlSessionConfiguration))
    }

    func processResponse(data: Data?, response: URLResponse?, error: Error?) throws -> [String: Any] {
        if error != nil || response == nil {
            return ["error": ["message": (error)?.localizedDescription ?? "Unknown error"]]
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
                var description = "Insert call failed with the following status code " + String(httpResponse.statusCode)
                if let safeData = data {
                    guard let errorResponse = try? JSONSerialization.jsonObject(with: safeData, options: .allowFragments) as? [String: Any] else {
                        return ["error": ["message": String(data: safeData, encoding: .utf8) ?? "Unknown error", "httpCode": httpResponse.statusCode]]
                    }
                    // Pass the vault's structured error object (grpcCode/httpStatus/details) through
                    // as-is, only patching in the request-id and defaulting httpCode when absent.
                    if var errorDict = errorResponse["error"] as? [String: Any] {
                        if let message = errorDict["message"] as? String {
                            description = message
                            if let requestId = httpResponse.allHeaderFields["x-request-id"] {
                                description += " - request-id: \(requestId)"
                            }
                            errorDict["message"] = description
                        }
                        if errorDict["httpCode"] == nil { errorDict["httpCode"] = httpResponse.statusCode }
                        return ["error": errorDict]
                    }
                    if let requestId = httpResponse.allHeaderFields["x-request-id"] {
                        description += " - request-id: \(requestId)"
                    }
                }
                return ["error": ["message": description, "httpCode": httpResponse.statusCode]]
            }
        }

        guard let safeData = data else {
            return ["records": []]
        }

        return try getCollectResponseBody(data: safeData)

    }

    func getCollectResponseBody(data: Data) throws -> [String: Any]{
        let jsonData = (try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]) ?? [:]
        var records: [[String: Any]] = []

        let responseRecords = jsonData["records"] as? [[String: Any]] ?? []
        for entry in responseRecords {
            if let error = entry["error"] as? String {
                var errorEntry: [String: Any] = ["error": error]
                if let skyflowID = entry["skyflowID"] { errorEntry["skyflowID"] = skyflowID }
                if let tableName = entry["tableName"] { errorEntry["tableName"] = tableName }
                if let httpCode = entry["httpCode"] { errorEntry["httpCode"] = httpCode }
                records.append(errorEntry)
            } else {
                var successEntry: [String: Any] = [:]
                if let skyflowID = entry["skyflowID"] { successEntry["skyflowID"] = skyflowID }
                if let tableName = entry["tableName"] { successEntry["tableName"] = tableName }
                // Both keys keep the FlowDB v2 wire names verbatim, and both are conditional: a
                // record with only non-tokenized additionalFields data has no "tokens" key at all,
                // and CollectRecord.tokens must read as nil (not [:]) in that case. Do not rename
                // these to the legacy PDB v1 SDK's "fields" vocabulary - the response contract this
                // intermediate dict carries is v2's, and the rename previously masked the
                // tokens/hashedData asymmetry that caused exactly that nil-vs-[:] bug.
                if let tokens = entry["tokens"] as? [String: Any] { successEntry["tokens"] = tokens }
                if let hashedData = entry["hashedData"] as? [String: Any] { successEntry["hashedData"] = hashedData }
                if let httpCode = entry["httpCode"] { successEntry["httpCode"] = httpCode }
                records.append(successEntry)
            }
        }

        return ["records": records]
    }
}
