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

        if let recordEntries = records["records"] as? [[String: Any]] {
            for record in recordEntries {
                if !(record["table"] is String) || !(record["fields"] is [String: Any]) {
                    callback.onFailure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid/Missing table or fields"]))
                    return
                }
            }
            self.apiClient.post(records: records, callback: callback, options: icOptions)
        } else {
            callback.onFailure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "No records array"]))
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

        if let tokens = records["records"] as? [[String: Any]] {
            var list: [RevealRequestRecord] = []
            for token in tokens {
                if let redaction = token["redaction"] as? RedactionType, let id = token["token"] as? String {
                    list.append(RevealRequestRecord(token: id, redaction: redaction.rawValue))
                } else {
                    return callback.onFailure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid/Missing ID or RedactionType format"]))
                }
            }
            self.apiClient.get(records: list, callback: callback)
        } else {
            callback.onFailure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "No records array"]))
        }
    }

    public func getById(records: [String: Any], callback: Callback) {
        if let entries = records["records"] as? [[String: Any]] {
            var list: [GetByIdRecord] = []
            for entry in entries {
                if let ids = entry["ids"] as? [String], let table = entry["table"] as? String, let redaction = entry["redaction"] as? RedactionType {
                    list.append(GetByIdRecord(ids: ids, table: table, redaction: redaction.rawValue))
                } else {
                    return callback.onFailure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid/Missing IDs, Table Name or RedactionType format"]))
                }
            }
            self.apiClient.getById(records: list, callback: callback)
        } else {
            callback.onFailure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "No records array"]))
        }
    }
}
