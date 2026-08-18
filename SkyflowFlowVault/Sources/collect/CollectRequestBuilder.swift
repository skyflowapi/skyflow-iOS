/*
 * Copyright (c) 2022 Skyflow
*/

// Builds the FlowDB v2 collect-side request bodies in stages: gathering the
// records from the mounted collect elements (plus additionalFields), then
// assembling the final insert / update-by-skyflowID wire payloads.
// Stateless builder: only static functions, never instantiated.

import Foundation

internal class CollectRequestBuilder {
    static var tableSet: Set<String> = Set<String>()
    static var callback: Callback?
    static var breakFlag = false
    static var mergedDict: [String: Any] = [:]
    
    internal static func addFieldsToTableSet(tableName: String, prefix: String, fields: [String: Any], contextOptions: ContextOptions) {
        if !self.breakFlag {
            for (key, val) in fields {
                if val is [String: Any] {
                    addFieldsToTableSet(tableName: tableName, prefix: prefix == "" ? key : prefix + "." + key, fields: val as! [String: Any], contextOptions: contextOptions)
                } else {
                    let tableSetEntry = tableName + "-" + (prefix == "" ? key : prefix + "." + key)
                    if tableSet.contains(tableSetEntry) {
                        if !self.breakFlag {
                            self.callback?.onFailure(ErrorCodes.DUPLICATE_ADDITIONAL_FIELD_FOUND(value: key).getErrorObject(contextOptions: contextOptions))
                            self.breakFlag = true
                            return
                        }
                    } else {
                        self.tableSet.insert(tableSetEntry)
                    }
                }
            }
        }
    }

    internal static func mergeFields(tableName: String, prefix: String, dict: [String: Any], contextOptions: ContextOptions) {
        for(key, val) in dict {
            let keypath = prefix == "" ? key : prefix + "." + key
            if val is [String: Any] {
                mergeFields(tableName: tableName, prefix: keypath, dict: val as! [String: Any], contextOptions: contextOptions)
            } else {
                if mergedDict[keyPath: keypath] == nil {
                    mergedDict[keyPath: keypath] = val
                } else {
                    if !self.breakFlag {
                        self.callback?.onFailure(ErrorCodes.DUPLICATE_ADDITIONAL_FIELD_FOUND(value: key).getErrorObject(contextOptions: contextOptions))
                        self.breakFlag = true
                        return
                    }
                }
            }
        }
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
        self.callback = callback
        self.breakFlag = false
        self.tableSet = Set<String>()
        var index: Int = 0

        if let additionalFields = additionalFields {
            for (recordIndex, entry) in additionalFields.records.enumerated() {
                let tableName = entry.tableName
                let fields = entry.data
                // An explicit empty-string skyflowId is a caller bug — reject it rather than
                // silently inserting a new row where an update was intended.
                if let skyflowId = entry.skyflowId, skyflowId.isEmpty {
                    self.callback?.onFailure(ErrorCodes.EMPTY_SKYFLOW_ID(value: "additional fields record at index \(recordIndex)").getErrorObject(contextOptions: contextOptions))
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
                    let inputEntry = payload[tableMap[tableName]!]
                    mergedDict = inputEntry["fields"] as! [String: Any]
                    self.mergeFields(tableName: tableName, prefix: "", dict: fields, contextOptions: contextOptions)
                    if self.breakFlag {
                        return nil
                    }
                    payload[tableMap[tableName]!]["fields"] = mergedDict
                    mergedDict = [:]
                } else {
                    tableMap[tableName] = index
                    let temp: [String: Any] = [
                        "table": tableName,
                        "fields": fields
                    ]
                    self.addFieldsToTableSet(tableName: tableName, prefix: "", fields: fields, contextOptions: contextOptions)
                    if self.breakFlag {
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
                self.callback?.onFailure(ErrorCodes.EMPTY_SKYFLOW_ID(value: "element with column '\(columnName)'").getErrorObject(contextOptions: contextOptions))
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
                            self.callback?.onFailure(ErrorCodes.DUPLICATE_ELEMENT_FOUND(values: [ element.columnName, element.tableName!]).getErrorObject(contextOptions: contextOptions))
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
                            self.callback?.onFailure(ErrorCodes.DUPLICATE_ELEMENT_FOUND(values: [ element.columnName, element.tableName!]).getErrorObject(contextOptions: contextOptions))
                            return nil
                        }
                        continue;
                    }
                    self.tableSet.insert(tableSetEntry)
                    payload[tableMap[(element.tableName)!]!] = temp
                } else {
                    tableMap[(element.tableName)!] = index
                    index += 1
                    var temp: [String: Any] = [
                        "table": element.tableName!,
                        "fields": [:]
                    ]
                    temp[keyPath: "fields." + element.columnName!] = element.getValue()
                    self.tableSet.insert(element.tableName! + "-" + element.columnName)
                    payload.append(temp)
                }
            }
        }
        return ["records": payload, "update": updatePayload]
    }

    // Stage 2a: assemble the final v2 insert payload (with upsert options).
    internal static func createInsertRequestBody(vaultID: String, records: [String: Any], upsert: [UpsertOption]? = nil) -> [String: Any] {
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
