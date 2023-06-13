/*
 * Copyright (c) 2022 Skyflow
*/

// Implementation of Skyflow Client class

import Foundation
import AEXML

public class Client {
    var vaultID: String
    var apiClient: APIClient
    var vaultURL: String
    var contextOptions: ContextOptions
    var elementLookup: [String: Any] = [:]
    
    public init(_ skyflowConfig: Configuration) {
        self.vaultID = skyflowConfig.vaultID
        self.vaultURL = skyflowConfig.vaultURL.hasSuffix("/") ? skyflowConfig.vaultURL + "v1/vaults/" : skyflowConfig.vaultURL + "/v1/vaults/"
        self.apiClient = APIClient(vaultID: skyflowConfig.vaultID, vaultURL: self.vaultURL, tokenProvider: skyflowConfig.tokenProvider)
        self.contextOptions = ContextOptions(logLevel: skyflowConfig.options!.logLevel, env: skyflowConfig.options!.env, interface: .CLIENT)
        Log.info(message: .CLIENT_INITIALIZED, contextOptions: self.contextOptions)
    }

    public func insert(records: [String: Any], options: InsertOptions = InsertOptions(), callback: Callback) {
        var tempContextOptions = self.contextOptions
        tempContextOptions.interface = .INSERT
        Log.info(message: .INSERT_TRIGGERED, contextOptions: tempContextOptions)
        if self.vaultID.isEmpty {
            let errorCode = ErrorCodes.EMPTY_VAULT_ID()
            return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        if self.vaultURL == "/v1/vaults/"  {
            let errorCode = ErrorCodes.EMPTY_VAULT_URL()
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
            for record in recordEntries {
                if record["table"] != nil {
                    if !(record["table"] is String) {
                        errorCode = .INVALID_TABLE_NAME_TYPE()
                    } else {
                        if (record["table"] as! String).isEmpty {
                            errorCode = .EMPTY_TABLE_NAME()
                        } else {
                            if record["fields"] != nil {
                                if !(record["fields"] is [String: Any]) {
                                    errorCode = .INVALID_FIELDS_TYPE()
                                    break
                                }
                                let fields = record["fields"] as! [String: Any]
                                if fields.isEmpty {
                                    errorCode = .EMPTY_FIELDS_KEY()
                                }
                             } else {
                                errorCode = .FIELDS_KEY_ERROR()
                             }
                         }
                    }
                } else {
                    errorCode = .TABLE_KEY_ERROR()
                }
            }
            if errorCode != nil {
                callback.onFailure(errorCode!.getErrorObject(contextOptions: tempContextOptions))
                return
            } else {
                if options.upsert != nil {
                    if icOptions.validateUpsert() {
                        return;
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

    public func container<T>(type: T.Type, options: ContainerOptions? = ContainerOptions()) -> Container<T>? {
        if options != nil {
            // Set options
        }

        if T.self == CollectContainer.self {
            Log.info(message: .COLLECT_CONTAINER_CREATED, contextOptions: self.contextOptions)
            return Container<T>(skyflow: self)
        }

        if T.self == RevealContainer.self {
            Log.info(message: .REVEAL_CONTAINER_CREATED, contextOptions: self.contextOptions)
            return Container<T>(skyflow: self)
        }

        return nil
    }

    public func detokenize(records: [String: Any], options: RevealOptions? = RevealOptions(), callback: Callback) {
        var tempContextOptions = self.contextOptions
        tempContextOptions.interface = .DETOKENIZE
        func checkRecord(_ token: [String: Any]) -> ErrorCodes? {
               if token["redaction"] != nil {
                   guard let _ = token["redaction"] as? RedactionType else {
                       return .INVALID_REDACTION_TYPE(value: String(describing: token["redaction"]!))
                   }
               }
                if token["token"] == nil {
                    return .ID_KEY_ERROR()
                } else {
                    guard let _ = token["token"] as? String else {
                        return .INVALID_TOKEN_TYPE()
                    }
                }
            return nil
        }

        Log.info(message: .DETOKENIZE_TRIGGERED, contextOptions: tempContextOptions)
        if self.vaultID.isEmpty {
            let errorCode = ErrorCodes.EMPTY_VAULT_ID()
            return callRevealOnFailure(callback: callback, errorObject: errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        if self.vaultURL == "/v1/vaults/"  {
            let errorCode = ErrorCodes.EMPTY_VAULT_URL()
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
            for token in tokens {
                let errorCode = checkRecord(token)
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
        if self.vaultID.isEmpty {
            let errorCode = ErrorCodes.EMPTY_VAULT_ID()
            return callRevealOnFailure(callback: callback, errorObject: errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        if self.vaultURL == "/v1/vaults/"  {
            let errorCode = ErrorCodes.EMPTY_VAULT_URL()
            return callRevealOnFailure(callback: callback, errorObject: errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        Log.info(message: .VALIDATE_GET_BY_ID_INPUT, contextOptions: tempContextOptions)

        func checkEntry(entry: [String: Any]) -> ErrorCodes? {
            if entry.isEmpty {
                return .EMPTY_RECORDS_OBJECT()
            }
            if entry["ids"] == nil {
                return .MISSING_KEY_IDS()
            }
            if !(entry["ids"] is [String]) {
                return .INVALID_IDS_TYPE()
            }
            if ((entry["ids"] as? [String])?.count == 0) {
                return .EMPTY_IDS()
            }
            let ids = entry["ids"] as! [String]
            for id in ids {
                if (id == "") {
                    return .EMPTY_ID_VALUE()
                }
            }
            if entry["table"] == nil {
                return .TABLE_KEY_ERROR()
            }
            if !(entry["table"] is String) {
                return .INVALID_TABLE_NAME_TYPE()
            }
            if ((entry["table"] as? String) == "") {
                return .EMPTY_TABLE_NAME()
            }
            if entry["redaction"] == nil {
                return .REDACTION_KEY_ERROR()
            }
            if (entry["redaction"] as? RedactionType) != nil {
                return nil
            } else {
                return .INVALID_REDACTION_TYPE(value: entry["redaction"] as! String)
            }
        }

        if records["records"] == nil {
            return callRevealOnFailure(callback: callback, errorObject: ErrorCodes.EMPTY_RECORDS_OBJECT().getErrorObject(contextOptions: tempContextOptions)) //Check
        }

        if let entries = records["records"] as? [[String: Any]] {
            var list: [GetByIdRecord] = []
            if entries.isEmpty {
                return callRevealOnFailure(callback: callback, errorObject: ErrorCodes.EMPTY_RECORDS_OBJECT().getErrorObject(contextOptions: tempContextOptions))
            }
            for entry in entries {
                let errorCode = checkEntry(entry: entry)
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
        if self.vaultID.isEmpty {
            let errorCode = ErrorCodes.EMPTY_VAULT_ID()
            return callRevealOnFailure(callback: callback, errorObject: errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        if self.vaultURL == "/v1/vaults/"  {
            let errorCode = ErrorCodes.EMPTY_VAULT_URL()
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
            for entry in entries {
                let errorCode = validateGetRecords(entry: entry, getOptions: options)
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
    internal func validateGetRecords(entry: [String: Any], getOptions: GetOptions) -> ErrorCodes? {
        if entry.isEmpty {
            return .EMPTY_RECORDS_OBJECT()
        }
        if (entry["ids"] != nil ){
            if !(entry["ids"] is [String]) {
                return .INVALID_IDS_TYPE()
            }
            if ((entry["ids"] as? [String])?.count == 0) {
                return .EMPTY_IDS()
            }
            let ids = entry["ids"] as! [String]
            for id in ids {
                if (id == "") {
                    return .EMPTY_ID_VALUE()
                }
            }
        }
        if entry["table"] == nil {
            return .TABLE_KEY_ERROR()
        }
        if !(entry["table"] is String) {
            return .INVALID_TABLE_NAME_TYPE()
        }
        if ((entry["table"] as? String) == "") {
            return .EMPTY_TABLE_NAME()
        }

        if( getOptions.tokens == true ){
            if (entry["columnName"] != nil || entry["columnValues"] != nil){
                return .TOKENS_GET_COLUMN_NOT_SUPPPORTED()
                
            }
            if (entry["redaction"] as? RedactionType) != nil {
                return .REDACTION_WITH_TOKEN_NOT_SUPPORTED()
            }
        } else {
            if entry["redaction"] == nil {
                return .REDACTION_KEY_ERROR()
            } else if (entry["redaction"] as? RedactionType) == nil {
                return .INVALID_REDACTION_TYPE(value: String(describing: entry["redaction"]))
            }
        }
                
        if(entry["columnName"] == nil){
            if ((entry["ids"] == nil) && (entry["columnValues"] == nil)){
                return .MISSING_IDS_OR_COLUMN_VALUES_IN_GET()
            }
        } else if (entry["columnName"] != nil && entry["columnValues"] == nil){
            return .MISSING_RECORD_COLUMN_VALUE()
        } else if !(entry["columnName"] is String){
            return .INVALID_COLUMN_NAME()
        } else if ((entry["ids"] != nil) && (entry["columnName"] != nil)){
            return .SKYFLOW_IDS_AND_COLUMN_NAME_BOTH_SPECIFIED()
        }
        if (entry["columnValues"] != nil){
            if ((entry["columnValues"] as? [String])?.count == 0) {
                return .EMPTY_RECORD_COLUMN_VALUES()
            }
            if !(entry["columnValues"] is [String]) {
                return .INVALID_COLUMN_VALUES_IN_GET()
            }
            if ((entry["columnValues"] as? [String])?.count == 0) {
                return .EMPTY_RECORD_COLUMN_VALUES()
            }
            let columnValues = entry["columnValues"] as! [String]
            for columnValue in columnValues {
                if (columnValue == "") {
                    return .EMPTY_COLUMN_VALUE()
                }
            }
            if( entry["columnName"] == nil ){
                return .MISSING_COLUMN_NAME()
            } else if((entry["columnName"] as? String) == ""){
                return .EMPTY_COLUMN_NAME()
            }
        }
        
        return nil
    }

    private func callRevealOnFailure(callback: Callback, errorObject: Error) {
        let result = ["errors": [errorObject]]
        callback.onFailure(result)
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

internal class LogCallback: Callback {
    var clientCallback: Callback
    var contextOptions: ContextOptions
    var onSuccessHandler: () -> Void
    var onFailureHandler: () -> Void

    public init(clientCallback: Callback, contextOptions: ContextOptions, onSuccessHandler: @escaping () -> Void, onFailureHandler: @escaping () -> Void) {
        self.clientCallback = clientCallback
        self.contextOptions = contextOptions
        self.onSuccessHandler = onSuccessHandler
        self.onFailureHandler = onFailureHandler
    }
    
    func onSuccess(_ responseBody: Any) {
        self.onSuccessHandler()
        clientCallback.onSuccess(responseBody)
    }
    
    func onFailure(_ error: Any) {
        self.onFailureHandler()
        clientCallback.onFailure(error)
    }
}
