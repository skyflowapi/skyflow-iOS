/*
 * Copyright (c) 2022 Skyflow
*/

// FlowVault (v2) entry points on the shared SkyflowCore Client class.
// The v2 operations live below as further extensions.
// Future enhancements specific to this SDK go in extensions in this target
// without affecting the legacy Skyflow SDK.

import Foundation

public extension Client {
    convenience init(_ skyflowConfig: Configuration) {
        self.init(skyflowConfig.data)
    }

    func container<T>(type: T.Type, options: ContainerOptions? = nil) -> Container<T>? {
        return makeContainer(type: type, options: options?.data)
    }

    // MARK: - FlowVault (v2) contract operations
    internal func insert(records: [String: Any], options: InsertOptions = InsertOptions(), callback: Callback) {
        var tempContextOptions = self.contextOptions
        tempContextOptions.interface = .INSERT
        Log.info(message: .INSERT_TRIGGERED, contextOptions: tempContextOptions)
        if let errorCode = RequestValidators.checkClientConfig(vaultID: self.vaultID, vaultURL: self.vaultURL) {
            return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
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
                self.apiClient.post(records: records, callback: logCallback, upsert: options.upsert, contextOptions: tempContextOptions)
            }
        } else {
            errorCode = .INVALID_RECORDS_TYPE()
            callback.onFailure(errorCode!.getErrorObject(contextOptions: tempContextOptions))
        }
    }

    internal func detokenize(records: [String: Any], options: RevealOptions? = RevealOptions(), callback: Callback) {
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
                    list.append(RevealRequestRecord(token: id))
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
            self.apiClient.get(records: list, tokenGroupRedactions: options?.tokenGroupRedactions, callback: logCallback, contextOptions: tempContextOptions)
        } else {
            callRevealOnFailure(callback: callback, errorObject: ErrorCodes.INVALID_RECORDS_TYPE().getErrorObject(contextOptions: tempContextOptions))
        }
    }

}
