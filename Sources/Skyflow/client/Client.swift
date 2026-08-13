/*
 * Copyright (c) 2022 Skyflow
*/

// Skyflow (legacy v1) entry points on the shared SkyflowCore Client class.
// The v1 operations live below as further extensions.
// Future enhancements specific to this SDK go in extensions in this target
// without affecting the FlowVault SDK.

import Foundation

extension Client {
    public convenience init(_ skyflowConfig: Configuration) {
        self.init(skyflowConfig.data)
    }

    public func container<T>(type: T.Type, options: ContainerOptions? = nil) -> Container<T>? {
        return makeContainer(type: type, options: options?.data)
    }

    // MARK: - Legacy (v1) contract operations

    public func insert(records: [String: Any], options: InsertOptions = InsertOptions(), callback: Callback) {
        var tempContextOptions = self.contextOptions
        tempContextOptions.interface = .INSERT
        Log.info(message: .INSERT_TRIGGERED, contextOptions: tempContextOptions)
        if let errorCode = RequestValidators.checkClientConfig(vaultID: self.vaultID, vaultURL: self.vaultURL) {
            return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        let icOptions = ICOptions(tokens: options.tokens, upsert: options.upsert, callback: callback, contextOptions: tempContextOptions)
        var errorCode: ErrorCodes?

        if records["records"] == nil {
            errorCode = .RECORDS_KEY_ERROR()
            callback.onFailure(errorCode!.getErrorObject(contextOptions: tempContextOptions))
            return
        }

        Log.info(message: .VALIDATE_RECORDS, contextOptions: tempContextOptions)
        if let recordEntries = records["records"] as? [[String: Any]] {
            for (index, record) in recordEntries.enumerated() {
                if record["table"] != nil {
                    if !(record["table"] is String) {
                        errorCode = .INVALID_TABLE_NAME_TYPE(value: "\(index)")
                    } else {
                        if (record["table"] as! String).isEmpty {
                            errorCode = .EMPTY_TABLE_NAME()
                        } else {
                            if record["fields"] != nil {
                                if !(record["fields"] is [String: Any]) {
                                    errorCode = .INVALID_FIELDS_TYPE(value: "\(index)")
                                    break
                                }
                                let fields = record["fields"] as! [String: Any]
                                if fields.isEmpty {
                                    errorCode = .EMPTY_FIELDS_KEY(value: "\(index)")
                                }
                             } else {
                                errorCode = .FIELDS_KEY_ERROR(value: "\(index)")
                             }
                         }
                    }
                } else {
                    errorCode = .TABLE_KEY_ERROR(value: "\(index)")
                }
            }
            if errorCode != nil {
                callback.onFailure(errorCode!.getErrorObject(contextOptions: tempContextOptions))
                return
            } else {
                if let upsert = options.upsert {
                    if let upsertError = RequestValidators.checkUpsertOptions(upsert) {
                        return callback.onFailure(upsertError.getErrorObject(contextOptions: tempContextOptions))
                    }
                }
                let logCallback = LogCallback(clientCallback: callback, contextOptions: tempContextOptions,
                    onSuccessHandler: {
                        Log.info(message: .INSERT_DATA_SUCCESS, contextOptions: tempContextOptions)
                    },
                    onFailureHandler: {
                    }
                )
                self.apiClient.post(records: records, callback: logCallback, options: icOptions, contextOptions: tempContextOptions)
            }
        } else {
            errorCode = .INVALID_RECORDS_TYPE()
            callback.onFailure(errorCode!.getErrorObject(contextOptions: tempContextOptions))
        }
    }

    public func detokenize(records: [String: Any], options: RevealOptions? = RevealOptions(), callback: Callback) {
        var tempContextOptions = self.contextOptions
        tempContextOptions.interface = .DETOKENIZE
        Log.info(message: .DETOKENIZE_TRIGGERED, contextOptions: tempContextOptions)
        if let errorCode = RequestValidators.checkClientConfig(vaultID: self.vaultID, vaultURL: self.vaultURL) {
            return callRevealOnFailure(callback: callback, errorObject: errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        Log.info(message: .VALIDATE_DETOKENIZE_INPUT, contextOptions: tempContextOptions)

        if records["records"] == nil {
            return callRevealOnFailure(callback: callback, errorObject: ErrorCodes.RECORDS_KEY_ERROR().getErrorObject(contextOptions: tempContextOptions))
        }

        if let tokens = records["records"] as? [[String: Any]] {
            var list: [RevealRequestRecord] = []
            if tokens.isEmpty {
                return callRevealOnFailure(callback: callback, errorObject: ErrorCodes.EMPTY_RECORDS_OBJECT().getErrorObject(contextOptions: tempContextOptions))
            }
            for (index,token) in tokens.enumerated() {
                let errorCode = RequestValidators.checkDetokenizeRecord(token: token, index: index)
                if errorCode == nil, let id = token["token"] as? String {
                    if token["redaction"] == nil{
                        list.append(RevealRequestRecord(token: id, redaction: RedactionType.PLAIN_TEXT.rawValue))
                    } else if let redaction = token["redaction"] as? RedactionType{
                        list.append(RevealRequestRecord(token: id, redaction: redaction.rawValue))
                    }
                } else {
                    return callRevealOnFailure(callback: callback, errorObject: errorCode!.getErrorObject(contextOptions: tempContextOptions))
                }
            }
            let logCallback = LogCallback(clientCallback: callback, contextOptions: tempContextOptions,
                onSuccessHandler: {
                    Log.info(message: .DETOKENIZE_SUCCESS, contextOptions: tempContextOptions)
                },
                onFailureHandler: {
                }
            )
            self.apiClient.get(records: list, callback: logCallback, contextOptions: tempContextOptions)
        } else {
            callRevealOnFailure(callback: callback, errorObject: ErrorCodes.INVALID_RECORDS_TYPE().getErrorObject(contextOptions: tempContextOptions))
        }
    }

    public func getById(records: [String: Any], callback: Callback) {
        var tempContextOptions = self.contextOptions
        tempContextOptions.interface = .GETBYID
        Log.info(message: .GET_BY_ID_TRIGGERED, contextOptions: tempContextOptions)
        if let errorCode = RequestValidators.checkClientConfig(vaultID: self.vaultID, vaultURL: self.vaultURL) {
            return callRevealOnFailure(callback: callback, errorObject: errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        Log.info(message: .VALIDATE_GET_BY_ID_INPUT, contextOptions: tempContextOptions)

        if records["records"] == nil {
            return callRevealOnFailure(callback: callback, errorObject: ErrorCodes.EMPTY_RECORDS_OBJECT().getErrorObject(contextOptions: tempContextOptions)) //Check
        }

        if let entries = records["records"] as? [[String: Any]] {
            var list: [GetByIdRecord] = []
            if entries.isEmpty {
                return callRevealOnFailure(callback: callback, errorObject: ErrorCodes.EMPTY_RECORDS_OBJECT().getErrorObject(contextOptions: tempContextOptions))
            }
            for (index, entry) in entries.enumerated() {
                let errorCode = RequestValidators.checkGetByIdEntry(entry: entry, index: index)
                if errorCode != nil {
                    return callRevealOnFailure(callback: callback, errorObject: errorCode!.getErrorObject(contextOptions: tempContextOptions))
                } else {
                    if let ids = entry["ids"] as? [String], let table = entry["table"] as? String, let redaction = entry["redaction"] as? RedactionType {
                        list.append(GetByIdRecord(ids: ids, table: table, redaction: redaction.rawValue))
                    }
                }
            }
            let logCallback = LogCallback(clientCallback: callback, contextOptions: tempContextOptions,
                onSuccessHandler: {
                    Log.info(message: .GET_BY_ID_SUCCESS, contextOptions: tempContextOptions)
                },
                onFailureHandler: {
                }
            )
            self.apiClient.getById(records: list, callback: logCallback, contextOptions: tempContextOptions)
        } else {
            callRevealOnFailure(callback: callback, errorObject: ErrorCodes.INVALID_RECORDS_TYPE().getErrorObject(contextOptions: tempContextOptions))
        }
    }
    public func get(records: [String: Any], options: GetOptions = GetOptions(), callback: Callback){
        var tempContextOptions = self.contextOptions
        tempContextOptions.interface = .GET
        Log.info(message: .GET_TRIGGERED, contextOptions: tempContextOptions)
        if let errorCode = RequestValidators.checkClientConfig(vaultID: self.vaultID, vaultURL: self.vaultURL) {
            return callRevealOnFailure(callback: callback, errorObject: errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        Log.info(message: .VALIDATE_GET_INPUT, contextOptions: tempContextOptions)

        if records["records"] == nil {
            return callRevealOnFailure(callback: callback, errorObject: ErrorCodes.EMPTY_RECORDS_OBJECT().getErrorObject(contextOptions: tempContextOptions))
        }
        if let entries = records["records"] as? [[String: Any]] {
            var list: [GetRecord] = []
            if entries.isEmpty {
                return callRevealOnFailure(callback: callback, errorObject: ErrorCodes.EMPTY_RECORDS_OBJECT().getErrorObject(contextOptions: tempContextOptions))
            }
            for (index,entry) in entries.enumerated() {
                let errorCode = RequestValidators.validateGetRecords(entry: entry, getOptions: options, index: index)
                if errorCode != nil {
                    return callRevealOnFailure(callback: callback, errorObject: errorCode!.getErrorObject(contextOptions: tempContextOptions))
                } else {
                    if let ids = entry["ids"] as? [String], let table = entry["table"] as? String {
                        if let redaction = entry["redaction"] as? RedactionType {
                            list.append(GetRecord(ids: ids, table: table, redaction: redaction.rawValue))
                        } else
                        {
                            list.append(GetRecord(ids: ids, table: table))
                        }

                    }
                    if let  columnValues = entry["columnValues"] as? [String], let table = entry["table"] as? String, let columnName  = entry["columnName"] as? String,  let redaction = entry["redaction"] as? RedactionType {
                        list.append(GetRecord(columnValues: columnValues, table: table, columnName: columnName, redaction: redaction.rawValue))
                    }
                }
            }
            let logCallback = LogCallback(clientCallback: callback, contextOptions: tempContextOptions, onSuccessHandler: {
                Log.info(message: .GET_SUCCESS, contextOptions: tempContextOptions)
            }, onFailureHandler: {

            })
            self.apiClient.getRecord(records: list, callback: logCallback, getOptions: options, contextOptions: tempContextOptions)
        } else {
            callRevealOnFailure(callback: callback, errorObject: ErrorCodes.INVALID_RECORDS_TYPE().getErrorObject(contextOptions: tempContextOptions))
        }
    }

    internal func createDetokenizeRecords(_ IDsToTokens: [String: String]) -> [String: [[String: String]]]{
        var records = [] as [[String : String]]
        var index = 0
        for (_, token) in IDsToTokens {
            records.append(["token": token])
            index += 1
        }

        return ["records": records]
    }

}
