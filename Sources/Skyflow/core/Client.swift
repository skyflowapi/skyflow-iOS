//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 19/07/21.
//
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
        let icOptions = ICOptions(tokens: options.tokens)
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

    private func callRevealOnFailure(callback: Callback, errorObject: Error) {
        let result = ["errors": [errorObject]]
        callback.onFailure(result)
    }

    public func invokeConnection(config: ConnectionConfig, callback: Callback) {
        var tempContextOptions = self.contextOptions
        tempContextOptions.interface = .INVOKE_CONNECTION
        Log.info(message: .INVOKE_CONNECTION_TRIGGERED, contextOptions: tempContextOptions)
        let connectionAPIClient = ConnectionAPIClient(callback: callback, contextOptions: tempContextOptions)

        do {
            let connectionTokenCallback = ConnectionTokenCallback(
                client: connectionAPIClient,
                connectionType: .REST,
                config: try config.convert(contextOptions: tempContextOptions),
                clientCallback: callback)
            self.apiClient.getAccessToken(callback: connectionTokenCallback, contextOptions: tempContextOptions)
        } catch {
            callRevealOnFailure(callback: callback, errorObject: error)
        }
    }
    
    public func invokeSoapConnection(config: SoapConnectionConfig, callback: Callback) {
        var tempContextOptions = self.contextOptions
        tempContextOptions.interface = .INVOKE_CONNECTION
        Log.info(message: .INVOKE_CONNECTION_TRIGGERED, contextOptions: tempContextOptions)
        if config.connectionURL.isEmpty {
            let errorCode = ErrorCodes.EMPTY_CONNECTION_URL()
            return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        if config.requestXML.isEmpty {
            let errorCode = ErrorCodes.EMPTY_REQUEST_XML()
            return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        do {
            let requestXMLDocument = try AEXMLDocument(xml: config.requestXML)
        }
        catch {
            let userInfo = (error as NSError).userInfo
            var errorCode = ErrorCodes.INVALID_REQUEST_XML(value : userInfo.description)
            if userInfo.isEmpty {
                errorCode = ErrorCodes.INVALID_REQUEST_XML(value: (error as NSError).description)
            }
            return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        let soapConnectionAPIClient = SoapConnectionAPIClient(callback: callback, skyflow: self, contextOptions: tempContextOptions)

        let soapConnectionTokenCallback = ConnectionTokenCallback(client: soapConnectionAPIClient, connectionType: .SOAP, config: config, clientCallback: callback)
        self.apiClient.getAccessToken(callback: soapConnectionTokenCallback, contextOptions: tempContextOptions)
    }
}

private class ConnectionTokenCallback: Callback {
    var client: Any
    var config: Any
    var clientCallback: Callback
    var connectionType: ConnectionType

    init(client: Any, connectionType: ConnectionType, config: Any, clientCallback: Callback) {
        self.client = client
        self.config = config
        self.clientCallback = clientCallback
        self.connectionType = connectionType
    }

    func onSuccess(_ responseBody: Any) {
        do {
            if connectionType == .REST {
            try (client as! ConnectionAPIClient).invokeConnection(
                token: responseBody as! String, config: config as! ConnectionConfig)
            }
            else {
                try (client as! SoapConnectionAPIClient).invokeSoapConnection(token: responseBody as! String, config: config as! SoapConnectionConfig)
            }
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

internal enum ConnectionType {
    case REST
    case SOAP
}
