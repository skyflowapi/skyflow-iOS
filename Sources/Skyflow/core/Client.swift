//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 19/07/21.
//
import Foundation

public class Client {
    var vaultID: String
    var apiClient: APIClient
    var vaultURL: String
    var contextOptions: ContextOptions

    public init(_ skyflowConfig: Configuration) {
        self.vaultID = skyflowConfig.vaultID
        self.vaultURL = skyflowConfig.vaultURL.hasSuffix("/") ? skyflowConfig.vaultURL + "v1/vaults/" : skyflowConfig.vaultURL + "/v1/vaults/"
        self.apiClient = APIClient(vaultID: skyflowConfig.vaultID, vaultURL: self.vaultURL, tokenProvider: skyflowConfig.tokenProvider)
        self.contextOptions = ContextOptions(logLevel: skyflowConfig.options!.logLevel)
//        Log.log(logLevel: .INFO, message: .INITIALIZE_CLIENT, values: ["123", "ABC"], contextOptions: self.contextOptions)
        Log.log(logLevel: .INFO, message: .CLIENT_INITIALIZED, contextOptions: self.contextOptions)
    }

    public func insert(records: [String: Any], options: InsertOptions? = InsertOptions(), callback: Callback) {
        Log.log(logLevel: .INFO, message: .INSERT_CALLED, contextOptions: self.contextOptions)
        let icOptions = ICOptions(tokens: options!.tokens)
        var errorCode: ErrorCodes? = nil
        
        if records["records"] == nil {
            errorCode = .RECORDS_KEY_ERROR()
            callback.onFailure(errorCode!.errorObject)
            return
        }

        Log.log(logLevel: .INFO, message: .VALIDATE_RECORDS, contextOptions: self.contextOptions)
        if let recordEntries = records["records"] as? [[String: Any]] {
            for record in recordEntries {
                if record["table"] != nil {
                    if !(record["table"] is String) {
                        errorCode = .INVALID_TABLE_NAME_TYPE()
                    }
                    else{
                         if record["fields"] != nil {
                            if !(record["fields"] is [String: Any]) {
                                errorCode = .INVALID_FIELDS_TYPE()
                            }
                         }
                         else {
                            errorCode = .FIELDS_KEY_ERROR()
                         }
                    }
                }
                else {
                    errorCode = .TABLE_KEY_ERROR()
                }
            }
            if errorCode != nil {
                callback.onFailure(errorCode!.errorObject)
                return
            }
            else {
                self.apiClient.post(records: records, callback: callback, options: icOptions)
            }
            let logCallback = LogCallback(clientCallback: callback, contextOptions: self.contextOptions,
                onSuccessHandler: {
                    Log.log(logLevel: .INFO, message: .INSERT_DATA_SUCCESS, contextOptions: self.contextOptions)
                },
                onFailureHandler: {
                }
            )
            self.apiClient.post(records: records, callback: logCallback, options: icOptions, contextOptions: self.contextOptions)
        } else {
            errorCode = .INVALID_RECORDS_TYPE()
            callback.onFailure(errorCode!.errorObject)
        }
    }

    public func container<T>(type: T.Type, options: ContainerOptions? = ContainerOptions()) -> Container<T>? {
        if options != nil {
            // Set options
        }

        if T.self == CollectContainer.self {
            Log.log(logLevel: .INFO, message: .COLLECT_CONTAINER_CREATED, contextOptions: self.contextOptions)
            return Container<T>(skyflow: self)
        }
        
        if T.self == RevealContainer.self {
            Log.log(logLevel: .INFO, message: .REVEAL_CONTAINER_CREATED, contextOptions: self.contextOptions)
            return Container<T>(skyflow: self)
        }

        return nil
    }

    public func detokenize(records: [String: Any], options: RevealOptions? = RevealOptions(), callback: Callback) {
        
        func checkRecord(_ token: [String: Any]) -> ErrorCodes? {
            if token["redaction"] == nil {
                return .REDACTION_KEY_ERROR()
            }
            if let _ = token["redaction"] as? RedactionType {
                if token["token"] == nil {
                    return .ID_KEY_ERROR()
                }
                else {
                    guard let _ = token["token"] as? String else {
                        return .INVALID_TOKEN_TYPE()
                    }
                }
            }
            else {
                return .INVALID_REDACTION_TYPE(value: token["redaction"] as! String )
            }
            return nil
        }
        
        Log.log(logLevel: .INFO, message: .DETOKENIZE_CALLED, contextOptions: self.contextOptions)
        Log.log(logLevel: .INFO, message: .VALIDATE_DETOKENIZE_INPUT, contextOptions: self.contextOptions)
        
        if records["records"] == nil {
            return callback.onFailure(ErrorCodes.RECORDS_KEY_ERROR().errorObject)
        }

        if let tokens = records["records"] as? [[String: Any]] {
            var list: [RevealRequestRecord] = []
            for token in tokens {
                let errorCode = checkRecord(token)
                if errorCode == nil, let redaction = token["redaction"] as? RedactionType, let id = token["token"] as? String {
                    list.append(RevealRequestRecord(token: id, redaction: redaction.rawValue))
                } else {
                    return callback.onFailure(errorCode!.errorObject)
                }
            }
            let logCallback = LogCallback(clientCallback: callback, contextOptions: self.contextOptions,
                onSuccessHandler: {
                    Log.log(logLevel: .INFO, message: .DETOKENIZE_SUCCESS, contextOptions: self.contextOptions)
                },
                onFailureHandler: {
                }
            )
            self.apiClient.get(records: list, callback: logCallback, contextOptions: contextOptions)
        } else {
            callback.onFailure(ErrorCodes.INVALID_RECORDS_TYPE().errorObject)
        }
    }

    public func getById(records: [String: Any], callback: Callback) {
        Log.log(logLevel: .INFO, message: .GET_BY_ID_CALLED, contextOptions: self.contextOptions)
        Log.log(logLevel: .INFO, message: .VALIDATE_GET_BY_ID_INPUT, contextOptions: self.contextOptions)
        if let entries = records["records"] as? [[String: Any]] {
            var list: [GetByIdRecord] = []
            for entry in entries {
                if let ids = entry["ids"] as? [String], let table = entry["table"] as? String, let redaction = entry["redaction"] as? RedactionType {
                    list.append(GetByIdRecord(ids: ids, table: table, redaction: redaction.rawValue))
                } else {
                    return callback.onFailure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid/Missing IDs, Table Name or RedactionType format"]))
                }
            }
            let logCallback = LogCallback(clientCallback: callback, contextOptions: self.contextOptions,
                onSuccessHandler: {
                    Log.log(logLevel: .INFO, message: .GET_BY_ID_SUCCESS, contextOptions: self.contextOptions)
                },
                onFailureHandler: {
                }
            )
            self.apiClient.getById(records: list, callback: logCallback, contextOptions: contextOptions)
        } else {
            callback.onFailure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "No records array"]))
        }
    }

    public func invokeGateway(config: GatewayConfig, callback: Callback) {
        Log.log(logLevel: .INFO, message: .INVOKE_GATEWAY_CALLED, contextOptions: self.contextOptions)
        let gatewayAPIClient = GatewayAPIClient(callback: callback)
        do {
            let gatewayTokenCallback = GatewayTokenCallback(client: gatewayAPIClient, config: try config.convert(), clientCallback: callback)
            self.apiClient.getAccessToken(callback: gatewayTokenCallback, contextOptions: self.contextOptions)
        } catch {
            callback.onFailure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
        }
    }
    
}

private class GatewayTokenCallback: Callback {
    var client: GatewayAPIClient
    var config: GatewayConfig
    var clientCallback: Callback

    init(client: GatewayAPIClient, config: GatewayConfig, clientCallback: Callback) {
        self.client = client
        self.config = config
        self.clientCallback = clientCallback
    }

    func onSuccess(_ responseBody: Any) {
        do {
            try client.invokeGateway(token: responseBody as! String, config: config.convert())
        } catch {
            self.onFailure(error)
        }
    }

    func onFailure(_ error: Error) {
        clientCallback.onFailure(error)
    }
}

internal class LogCallback: Callback {
    
    var clientCallback: Callback
    var contextOptions: ContextOptions
    var onSuccessHandler: () -> Void
    var onFailureHandler: () -> Void
    
    public init(clientCallback: Callback, contextOptions: ContextOptions, onSuccessHandler: @escaping () -> Void, onFailureHandler: @escaping () -> Void){
        self.clientCallback = clientCallback
        self.contextOptions = contextOptions
        self.onSuccessHandler = onSuccessHandler
        self.onFailureHandler = onFailureHandler
    }
    func onSuccess(_ responseBody: Any) {
        self.onSuccessHandler()
        clientCallback.onSuccess(responseBody)
    }
    func onFailure(_ error: Error) {
        self.onFailureHandler()
        clientCallback.onFailure(error)
    }
}
