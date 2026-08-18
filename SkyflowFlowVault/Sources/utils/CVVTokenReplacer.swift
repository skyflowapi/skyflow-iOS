/*
 * Copyright (c) 2022 Skyflow
*/

// Captures entered CVV values at request-assembly time and swaps the real CVV token(s) in a
// FlowDB v2 collect response with a mock placeholder, before the response reaches the app.

import Foundation

// column -> entered value, keyed by table name (inserts) or skyflowId (updates).
internal struct CVVCaptureMap {
    var byTable: [String: [String: String]] = [:]
    var byRecordId: [String: [String: String]] = [:]

    var isEmpty: Bool { byTable.isEmpty && byRecordId.isEmpty }
}

internal enum CVVTokenReplacer {
    // An optional CVV element left blank still submits "" to the vault and can get a real token
    // back for it - always capture the column (even when empty) so that token gets replaced with
    // "" too (see applyMock below), rather than leaking the real vault token unmasked.
    //
    // First element wins per (table/recordId, column) - mirrors the existing dedup behavior in
    // CollectRequestBuilder, where a second element sharing a column (ElementValueMatchRule)
    // is dropped rather than merged.
    internal static func captureCVVMap(elements: [TextField]) -> CVVCaptureMap {
        var map = CVVCaptureMap()
        for element in elements {
            guard element.fieldType == .CVV, element.returnMockValue, let columnName = element.columnName else { continue }
            let value = element.getValue()

            if let skyflowId = element.skyflowId, !skyflowId.isEmpty {
                if map.byRecordId[skyflowId]?[columnName] == nil {
                    map.byRecordId[skyflowId, default: [:]][columnName] = value
                }
            } else if let tableName = element.tableName {
                if map.byTable[tableName]?[columnName] == nil {
                    map.byTable[tableName, default: [:]][columnName] = value
                }
            }
        }
        return map
    }

    internal static func replaceCVVTokens(in records: [[String: Any]], cvvMap: CVVCaptureMap) -> [[String: Any]] {
        guard !cvvMap.isEmpty else { return records }

        return records.map { record in
            guard record["error"] == nil, var fields = record["fields"] as? [String: Any] else { return record }

            let cvvColumns: [String: String]?
            if let skyflowId = record["skyflowID"] as? String, let byId = cvvMap.byRecordId[skyflowId] {
                cvvColumns = byId
            } else if let tableName = record["tableName"] as? String, let byTable = cvvMap.byTable[tableName] {
                cvvColumns = byTable
            } else {
                cvvColumns = nil
            }

            guard let columns = cvvColumns else { return record }

            for (capturedColumn, enteredValue) in columns {
                applyMock(to: &fields, capturedColumn: capturedColumn, enteredValue: enteredValue)
            }

            var record = record
            record["fields"] = fields
            return record
        }
    }

    // Splits a (possibly nested) captured column at the first "." into a top-level response key
    // and a nested path, then replaces the token(s) matching that key/path in the response's raw
    // token-entry list for that column, leaving every other entry (and every other column) intact.
    private static func applyMock(to fields: inout [String: Any], capturedColumn: String, enteredValue: String) {
        let parts = capturedColumn.split(separator: ".", maxSplits: 1).map(String.init)
        let topKey = parts[0]
        let nestedPath = parts.count > 1 ? parts[1] : nil

        guard var entries = fields[topKey] as? [[String: Any]] else { return }

        // Empty entered value → replace real vault token with "" (field was left blank).
        // Otherwise use the hardcoded constant for the detected length so the app never
        // receives the actual CVV token: "817" for 3-digit, "8173" for 4-digit.
        let mock: String
        if enteredValue.isEmpty {
            mock = ""
        } else {
            mock = enteredValue.count == 4 ? "8173" : "817"
        }

        for index in entries.indices {
            let entryPath = entries[index]["path"] as? String
            if nestedPath == nil {
                if entryPath == nil {
                    entries[index]["token"] = mock
                }
            } else if entryPath == nestedPath {
                entries[index]["token"] = mock
            }
        }

        fields[topKey] = entries
    }
}

// Wraps another Callback and swaps CVV tokens in "records" (if present) before forwarding the
// response onward. Inserted between the container's collect() and its existing LogCallback, so
// no changes are needed to the network/response-parsing classes or APIClient.
internal class CVVMaskingCallback: Callback {
    private let cvvMap: CVVCaptureMap
    private let wrapped: Callback

    internal init(cvvMap: CVVCaptureMap, wrapping callback: Callback) {
        self.cvvMap = cvvMap
        self.wrapped = callback
    }

    internal func onSuccess(_ responseBody: Any) {
        wrapped.onSuccess(mask(responseBody))
    }

    internal func onFailure(_ error: Any) {
        wrapped.onFailure(mask(error))
    }

    // A partial-batch failure can still carry a "records" array alongside "errors", so both
    // onSuccess and onFailure bodies need the same masking.
    private func mask(_ body: Any) -> Any {
        guard cvvMap.isEmpty == false,
              var dict = body as? [String: Any],
              let records = dict["records"] as? [[String: Any]] else { return body }

        dict["records"] = CVVTokenReplacer.replaceCVVTokens(in: records, cvvMap: cvvMap)
        return dict
    }
}
