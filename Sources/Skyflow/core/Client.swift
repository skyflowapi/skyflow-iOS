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

    public init(_ skyflowConfig: Configuration) {
        self.vaultID = skyflowConfig.vaultID
        self.vaultURL = skyflowConfig.vaultURL.hasSuffix("/") ? skyflowConfig.vaultURL + "v1/vaults/" : skyflowConfig.vaultURL + "/v1/vaults/"
        self.apiClient = APIClient(vaultID: skyflowConfig.vaultID, vaultURL: self.vaultURL, tokenProvider: skyflowConfig.tokenProvider)
    }

    public func insert(records: [String: Any], options: InsertOptions? = InsertOptions(), callback: Callback) {
        let icOptions = ICOptions(tokens: options!.tokens)
        var errorCode: ErrorCodes? = nil
        
        if records["records"] == nil {
            errorCode = .RECORDS_KEY_ERROR()
            callback.onFailure(errorCode!.errorObject)
            return
        }

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
        } else {
            errorCode = .INVALID_RECORDS_TYPE()
            callback.onFailure(errorCode!.errorObject)
        }
    }

    public func container<T>(type: T.Type, options: ContainerOptions? = ContainerOptions()) -> Container<T>? {
        if options != nil {
            // Set options
        }

        if T.self == CollectContainer.self || T.self == RevealContainer.self {
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
        
        
        if records["records"] == nil {
            return callRevealOnFailure(callback: callback, errorObject: ErrorCodes.RECORDS_KEY_ERROR().errorObject)
        }
        if let tokens = records["records"] as? [[String: Any]] {
            var list: [RevealRequestRecord] = []
            for token in tokens {
                let errorCode = checkRecord(token)
                if errorCode == nil, let redaction = token["redaction"] as? RedactionType, let id = token["token"] as? String {
                    list.append(RevealRequestRecord(token: id, redaction: redaction.rawValue))
                } else {
                    return callRevealOnFailure(callback: callback, errorObject: errorCode!.errorObject)
                }
            }
            self.apiClient.get(records: list, callback: callback)
        } else {
            callRevealOnFailure(callback: callback, errorObject: ErrorCodes.INVALID_RECORDS_TYPE().errorObject)
        }
    }

    public func getById(records: [String: Any], callback: Callback) {
        
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
            if (entry["redaction"] as? RedactionType) != nil{
                return nil
            }
            else {
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
                    return callRevealOnFailure(callback: callback, errorObject: errorCode!.errorObject)
                }
                else{
                    if let ids = entry["ids"] as? [String], let table = entry["table"] as? String, let redaction = entry["redaction"] as? RedactionType {
                        list.append(GetByIdRecord(ids: ids, table: table, redaction: redaction.rawValue))
                    }
                }
            }
            self.apiClient.getById(records: list, callback: callback)
        } else {
            callRevealOnFailure(callback: callback, errorObject: ErrorCodes.INVALID_RECORDS_TYPE().errorObject)
        }
    }
    
    private func callRevealOnFailure(callback: Callback, errorObject: NSError) {
        let result = ["errors": errorObject]
        callback.onFailure(result)
    }

    public func invokeGateway(config: GatewayConfig, callback: Callback) {
        let gatewayAPIClient = GatewayAPIClient(callback: callback)
        

        do {
            self.apiClient.getAccessToken(callback: GatewayTokenCallback(client: gatewayAPIClient, config: try config.convert(), clientCallback: callback))
        } catch {
            callback.onFailure(error)
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
            clientCallback.onFailure(error)
        }
    }

    func onFailure(_ error: Any) {
        clientCallback.onFailure(error)
    }
}
