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
        self.contextOptions = ContextOptions(logLevel: skyflowConfig.options!.logLevel, env: skyflowConfig.options!.env)
        Log.info(message: .CLIENT_INITIALIZED, contextOptions: self.contextOptions)
    }

    public func insert(records: [String: Any], options: InsertOptions? = InsertOptions(), callback: Callback) {
        Log.info(message: .INSERT_TRIGGERED, contextOptions: self.contextOptions)
        let icOptions = ICOptions(tokens: options!.tokens)
        var errorCode: ErrorCodes?

        if records["records"] == nil {
            errorCode = .RECORDS_KEY_ERROR()
            callback.onFailure(errorCode!.getErrorObject(contextOptions: self.contextOptions))
            return
        }

        Log.info(message: .VALIDATE_RECORDS, contextOptions: self.contextOptions)
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
                callback.onFailure(errorCode!.getErrorObject(contextOptions: self.contextOptions))
                return
            } else {
                let logCallback = LogCallback(clientCallback: callback, contextOptions: self.contextOptions,
                    onSuccessHandler: {
                        Log.info(message: .INSERT_DATA_SUCCESS, contextOptions: self.contextOptions)
                    },
                    onFailureHandler: {
                    }
                )
                self.apiClient.post(records: records, callback: logCallback, options: icOptions, contextOptions: self.contextOptions)
            }
        } else {
            errorCode = .INVALID_RECORDS_TYPE()
            callback.onFailure(errorCode!.getErrorObject(contextOptions: self.contextOptions))
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
        func checkRecord(_ token: [String: Any]) -> ErrorCodes? {
                if token["token"] == nil {
                    return .ID_KEY_ERROR()
                } else {
                    guard let _ = token["token"] as? String else {
                        return .INVALID_TOKEN_TYPE()
                    }
                }
            return nil
        }

        Log.info(message: .DETOKENIZE_TRIGGERED, contextOptions: self.contextOptions)
        Log.info(message: .VALIDATE_DETOKENIZE_INPUT, contextOptions: self.contextOptions)

        if records["records"] == nil {
            return callRevealOnFailure(callback: callback, errorObject: ErrorCodes.RECORDS_KEY_ERROR().getErrorObject(contextOptions: self.contextOptions))
        }

        if let tokens = records["records"] as? [[String: Any]] {
            var list: [RevealRequestRecord] = []
            for token in tokens {
                let errorCode = checkRecord(token)
                if errorCode == nil, let id = token["token"] as? String {
                    list.append(RevealRequestRecord(token: id))
                } else {
                    return callRevealOnFailure(callback: callback, errorObject: errorCode!.getErrorObject(contextOptions: self.contextOptions))
                }
            }
            let logCallback = LogCallback(clientCallback: callback, contextOptions: self.contextOptions,
                onSuccessHandler: {
                    Log.info(message: .DETOKENIZE_SUCCESS, contextOptions: self.contextOptions)
                },
                onFailureHandler: {
                }
            )
            self.apiClient.get(records: list, callback: logCallback, contextOptions: contextOptions)
        } else {
            callRevealOnFailure(callback: callback, errorObject: ErrorCodes.INVALID_RECORDS_TYPE().getErrorObject(contextOptions: self.contextOptions))
        }
    }

    public func getById(records: [String: Any], callback: Callback) {
        Log.info(message: .GET_BY_ID_TRIGGERED, contextOptions: self.contextOptions)
        Log.info(message: .VALIDATE_GET_BY_ID_INPUT, contextOptions: self.contextOptions)

        func checkEntry(entry: [String: Any]) -> ErrorCodes? {
            if entry["ids"] == nil {
                return .MISSING_KEY_IDS()
            }
            if !(entry["ids"] is [String]) {
                return .INVALID_IDS_TYPE()
            }
            if entry["table"] == nil {
                return .TABLE_KEY_ERROR()
            }
            if !(entry["table"] is String) {
                return .INVALID_TABLE_NAME_TYPE()
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
            return callRevealOnFailure(callback: callback, errorObject: ErrorCodes.RECORDS_KEY_ERROR().errorObject)
        }

        if let entries = records["records"] as? [[String: Any]] {
            var list: [GetByIdRecord] = []
            for entry in entries {
                let errorCode = checkEntry(entry: entry)
                if errorCode != nil {
                    return callRevealOnFailure(callback: callback, errorObject: errorCode!.getErrorObject(contextOptions: self.contextOptions))
                } else {
                    if let ids = entry["ids"] as? [String], let table = entry["table"] as? String, let redaction = entry["redaction"] as? RedactionType {
                        list.append(GetByIdRecord(ids: ids, table: table, redaction: redaction.rawValue))
                    }
                }
            }
            let logCallback = LogCallback(clientCallback: callback, contextOptions: self.contextOptions,
                onSuccessHandler: {
                    Log.info(message: .GET_BY_ID_SUCCESS, contextOptions: self.contextOptions)
                },
                onFailureHandler: {
                }
            )
            self.apiClient.getById(records: list, callback: logCallback, contextOptions: contextOptions)
        } else {
            callRevealOnFailure(callback: callback, errorObject: ErrorCodes.INVALID_RECORDS_TYPE().getErrorObject(contextOptions: self.contextOptions))
        }
    }

    private func callRevealOnFailure(callback: Callback, errorObject: Error) {
        let result = ["errors": [errorObject]]
        callback.onFailure(result)
    }

    public func invokeGateway(config: GatewayConfig, callback: Callback) {
        Log.info(message: .INVOKE_GATEWAY_TRIGGERED, contextOptions: self.contextOptions)
        let gatewayAPIClient = GatewayAPIClient(callback: callback, contextOptions: self.contextOptions)

        do {
            let gatewayTokenCallback = GatewayTokenCallback(client: gatewayAPIClient, config: try config.convert(contextOptions: self.contextOptions), clientCallback: callback)
            self.apiClient.getAccessToken(callback: gatewayTokenCallback, contextOptions: self.contextOptions)
        } catch {
            callRevealOnFailure(callback: callback, errorObject: error)
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
            try client.invokeGateway(token: responseBody as! String, config: config)
        } catch {
            clientCallback.onFailure(error)
        }
    }

    func onFailure(_ error: Any) {
        clientCallback.onFailure(error)
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
