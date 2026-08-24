/*
 * Copyright (c) 2022 Skyflow
*/

// Builds the FlowDB v2 collect-side request bodies in stages: gathering the
// records from the mounted collect elements (plus additionalFields), then
// assembling the final insert / update-by-skyflowID wire payloads.
// Stateless builder: only static functions, never instantiated.

import Foundation

internal class CollectRequestBuilder {
    // Returns true if a duplicate was found (and callback.onFailure has already been called) -
    // the caller should treat that as "stop, return nil". `tableSet` is per-call local state
    // threaded through via inout, not shared static state: two concurrent collect() calls
    // (different containers, or a rapid double-tap) must not race on the same Set.
    internal static func addFieldsToTableSet(tableName: String, prefix: String, fields: [String: Any], tableSet: inout Set<String>, callback: Callback, contextOptions: ContextOptions) -> Bool {
        for (key, val) in fields {
            if let nestedFields = val as? [String: Any] {
                if addFieldsToTableSet(tableName: tableName, prefix: prefix == "" ? key : prefix + "." + key, fields: nestedFields, tableSet: &tableSet, callback: callback, contextOptions: contextOptions) {
                    return true
                }
            } else {
                let tableSetEntry = tableName + "-" + (prefix == "" ? key : prefix + "." + key)
                if tableSet.contains(tableSetEntry) {
                    callback.onFailure(ErrorCodes.DUPLICATE_ADDITIONAL_FIELD_FOUND(value: key).getErrorObject(contextOptions: contextOptions))
                    return true
                } else {
                    tableSet.insert(tableSetEntry)
                }
            }
        }
        return false
    }

    // Same per-call-local pattern as addFieldsToTableSet above, for the same reentrancy reason.
    internal static func mergeFields(tableName: String, prefix: String, dict: [String: Any], mergedDict: inout [String: Any], callback: Callback, contextOptions: ContextOptions) -> Bool {
        for (key, val) in dict {
            let keypath = prefix == "" ? key : prefix + "." + key
            if let nestedVal = val as? [String: Any] {
                if mergeFields(tableName: tableName, prefix: keypath, dict: nestedVal, mergedDict: &mergedDict, callback: callback, contextOptions: contextOptions) {
                    return true
                }
            } else {
                if mergedDict[keyPath: keypath] == nil {
                    mergedDict[keyPath: keypath] = val
                } else {
                    callback.onFailure(ErrorCodes.DUPLICATE_ADDITIONAL_FIELD_FOUND(value: key).getErrorObject(contextOptions: contextOptions))
                    return true
                }
            }
        }
        return false
    }

    // Stage 1: gather the records from the mounted collect elements and
    // additionalFields, split into insert ("records") and update buckets.
    internal static func createCollectRecords(
        elements: [TextField],
        additionalFields: AdditionalFields? = nil,
        callback: Callback,
        contextOptions: ContextOptions
    ) -> [String: Any]? {
        var tableMap: [String: Int] = [:]
        var payload: [[String: Any]] = []
        var updatePayload: [String: Any] = [:]
        var tableSet = Set<String>()
        var index: Int = 0

        if let additionalFields = additionalFields {
            for (recordIndex, entry) in additionalFields.records.enumerated() {
                let tableName = entry.tableName
                let fields = entry.data
                // An explicit empty-string skyflowId is a caller bug — reject it rather than
                // silently inserting a new row where an update was intended.
                if let skyflowId = entry.skyflowId, skyflowId.isEmpty {
                    callback.onFailure(ErrorCodes.EMPTY_SKYFLOW_ID(value: "additional fields record at index \(recordIndex)").getErrorObject(contextOptions: contextOptions))
                    return nil
                }
                if let skyflowId = entry.skyflowId, !skyflowId.isEmpty {
                    if updatePayload[skyflowId] != nil {
                        let temp = updatePayload[skyflowId] as! [String: Any]
                        var existingFields = temp["fields"] as! [String: Any]
                        for (key, val) in fields {
                            existingFields[key] = val
                        }
                        var updatedTemp = temp
                        updatedTemp["fields"] = existingFields
                        updatePayload[skyflowId] = updatedTemp
                    } else {
                        let temp: [String: Any] = [
                            "table": tableName,
                            "fields": fields,
                            "skyflowId": skyflowId
                        ]
                        updatePayload[skyflowId] = temp
                    }
                    continue
                }
                if tableMap[tableName] != nil {
                    var mergedDict = payload[tableMap[tableName]!]["fields"] as! [String: Any]
                    let hadDuplicate = self.mergeFields(tableName: tableName, prefix: "", dict: fields, mergedDict: &mergedDict, callback: callback, contextOptions: contextOptions)
                    if hadDuplicate {
                        return nil
                    }
                    payload[tableMap[tableName]!]["fields"] = mergedDict
                } else {
                    tableMap[tableName] = index
                    let temp: [String: Any] = [
                        "table": tableName,
                        "fields": fields
                    ]
                    let hadDuplicate = self.addFieldsToTableSet(tableName: tableName, prefix: "", fields: fields, tableSet: &tableSet, callback: callback, contextOptions: contextOptions)
                    if hadDuplicate {
                        return nil
                    }
                    payload.append(temp)
                    index += 1
                }
            }
        }

        for element in elements {
            // Safe: setupField() unconditionally copies these from collectInput onto every
            // element the moment it's created via container.create() - elements is only ever
            // populated with elements that have already gone through that path.
            let tableName = element.tableName!
            let columnName = element.columnName!
            let value = element.getValue()
            let skyflowId = element.skyflowId

            // Same guard as additionalFields above: CollectElementInput now defaults
            // skyflowId to nil, so an empty string can only be an explicit caller mistake.
            if let skyflowId = skyflowId, skyflowId.isEmpty {
                callback.onFailure(ErrorCodes.EMPTY_SKYFLOW_ID(value: "element with column '\(columnName)'").getErrorObject(contextOptions: contextOptions))
                return nil
            }
            if let skyflowId = skyflowId, !skyflowId.isEmpty {
                if updatePayload[skyflowId] != nil {
                    var temp = updatePayload[skyflowId] as! [String: Any]
                    var existingFields = temp["fields"] as! [String: Any]
                    if existingFields[columnName] != nil {
                        var hasElementValueMatchRule: Bool = false
                        for validation in element.userValidationRules.rules {
                            if validation is ElementValueMatchRule {
                                hasElementValueMatchRule = true
                                break;
                            }
                        }
                        if(!hasElementValueMatchRule)
                        {
                            callback.onFailure(ErrorCodes.DUPLICATE_ELEMENT_FOUND(values: [ element.columnName, element.tableName!]).getErrorObject(contextOptions: contextOptions))
                            return nil
                        }
                        continue;
                    } else {
                        existingFields[columnName] = value
                    }
                    temp["fields"] = existingFields
                    updatePayload[skyflowId] = temp
                } else {
                    let temp: [String: Any] = [
                        "table": tableName,
                        "fields": [columnName: value],
                        "skyflowId": skyflowId
                    ]
                    updatePayload[skyflowId] = temp
                }
            } else {
                // Only add to payload
                if tableMap[(element.tableName)!] != nil {
                    var temp = payload[tableMap[(element.tableName)!]!]
                    temp[keyPath: "fields." + (element.columnName)!] = element.getValue()
                    let tableSetEntry = element.tableName! + "-" + element.columnName
                    if tableSet.contains(tableSetEntry) {
                        var hasElementValueMatchRule: Bool = false
                        for validation in element.userValidationRules.rules {
                            if validation is ElementValueMatchRule {
                                hasElementValueMatchRule = true
                                break;
                            }
                        }
                        if(!hasElementValueMatchRule)
                        {
                            callback.onFailure(ErrorCodes.DUPLICATE_ELEMENT_FOUND(values: [ element.columnName, element.tableName!]).getErrorObject(contextOptions: contextOptions))
                            return nil
                        }
                        continue;
                    }
                    tableSet.insert(tableSetEntry)
                    payload[tableMap[(element.tableName)!]!] = temp
                } else {
                    tableMap[(element.tableName)!] = index
                    index += 1
                    var temp: [String: Any] = [
                        "table": element.tableName!,
                        "fields": [:]
                    ]
                    temp[keyPath: "fields." + element.columnName!] = element.getValue()
                    tableSet.insert(element.tableName! + "-" + element.columnName)
                    payload.append(temp)
                }
            }
        }
        return ["records": payload, "update": updatePayload]
    }

    // Stage 2a: assemble the final v2 insert payload (with upsert options).
    internal static func createInsertRequestBody(vaultID: String, records: [String: Any], upsert: [UpsertOptions]? = nil) -> [String: Any] {
        var recordsPayload: [[String: Any]] = []
        for record in (records["records"] as! [[String: Any]]) {
            var temp: [String: Any] = [:]
            temp["data"] = record["fields"]
            if let tableName = record["table"] as? String {
                temp["tableName"] = tableName
                if let upsertOptions = upsert, let match = upsertOptions.first(where: { $0.tableName == tableName }) {
                    var upsertPayload: [String: Any] = ["uniqueColumns": match.uniqueColumns]
                    if let updateType = match.updateType {
                        upsertPayload["updateType"] = updateType.rawValue
                    }
                    temp["upsert"] = upsertPayload
                }
            }
            recordsPayload.append(temp)
        }
        return ["vaultID": vaultID, "records": recordsPayload]
    }

    // Stage 2b: assemble the final v2 update-by-skyflowID payload.
    internal static func createUpdateRequestBody(vaultID: String, records: [[String: Any]]) -> [String: Any] {
        return ["vaultID": vaultID, "records": records]
    }
}
