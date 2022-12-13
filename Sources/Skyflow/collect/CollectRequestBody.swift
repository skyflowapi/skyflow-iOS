/*
 * Copyright (c) 2022 Skyflow
 */

// Class for formatting the request body for collecting the data

import Foundation

internal class CollectRequestBody {
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
                            self.callback?.onFailure(ErrorCodes.DUPLICATE_ADDITIONAL_FIELD_FOUND(values: [tableName, key]).getErrorObject(contextOptions: contextOptions))
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
                        self.callback?.onFailure(ErrorCodes.DUPLICATE_ADDITIONAL_FIELD_FOUND(values: [tableName, key]).getErrorObject(contextOptions: contextOptions))
                        self.breakFlag = true
                        return
                    }
                }
            }
        }
    }

    internal static func createRequestBody(elements: [TextField], additionalFields: [String: Any]? = nil, callback: Callback, contextOptions: ContextOptions) -> [String: Any]? {
        var tableMap: [String: Int] = [:]
        var payload: [[String: Any]] = []
        self.callback = callback
        self.breakFlag = false
        self.tableSet = Set<String>()
        var index: Int = 0
        var inputPayload: [[String: Any]] = []

        if additionalFields != nil {
            inputPayload = additionalFields?["records"] as! [[String: Any]]
            for entry in inputPayload {
                let entryDict = entry
                let tableName = entryDict["table"] as! String
                let fields = entryDict["fields"] as! [String: Any]
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
            if tableMap[(element.tableName)!] != nil {
                var temp = payload[tableMap[(element.tableName)!]!]
                temp[keyPath: "fields." + (element.columnName)!] = element.getValue()
                let tableSetEntry = element.tableName! + "-" + element.columnName
                if tableSet.contains(tableSetEntry) {
                    var hasElementValueMatchRule = false
                    for validation in element.userValidationRules.rules {
                        if validation is ElementValueMatchRule {
                            hasElementValueMatchRule = true
                            break
                        }
                    }
                    if !hasElementValueMatchRule {
                        self.callback?.onFailure(ErrorCodes.DUPLICATE_ELEMENT_FOUND(values: [element.tableName!, element.columnName]).getErrorObject(contextOptions: contextOptions))
                        return nil
                    }
                    continue
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
        return ["records": payload]
    }
    internal static func getUniqueColumn(tableName: String, upsert: [[String: Any]]) -> String {
        var uniqueColumn = ""
        for currUpsertOption in upsert {
            if currUpsertOption["table"] as! String == tableName {
                uniqueColumn = currUpsertOption["column"] as! String
            }
        }
        return uniqueColumn
    }
}
