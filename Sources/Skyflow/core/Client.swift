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
    
    public init(_ skyflowConfig: Configuration){
        self.vaultID = skyflowConfig.vaultID
        self.vaultURL = skyflowConfig.vaultURL
        self.apiClient = APIClient(vaultID: skyflowConfig.vaultID, vaultURL: skyflowConfig.vaultURL, tokenProvider: skyflowConfig.tokenProvider)
    }
    
    public func insert(records: [String: Any], options: InsertOptions? = InsertOptions(), callback: Callback){
        self.apiClient.post(records: records, callback: callback, options: options!)
    }
    
    public func container<T>(type: T.Type, options: ContainerOptions? = ContainerOptions()) -> Container<T>? {
        
        if options != nil {
            //Set options
        }
        
        if T.self == CollectContainer.self || T.self == RevealContainer.self {
            return Container<T>(skyflow: self)
        }

        return nil
    }
    
    public func get(records: [String: Any], options: RevealOptions? = RevealOptions(), callback: Callback)   {
        let tokens : [[String : Any]] = records["records"] as! [[String : Any]]
        var list : [RevealRequestRecord] = []
        for token in tokens
        {
            if let redaction = token["redaction"] as? RedactionType, let id = token["id"] as? String {
            list.append(RevealRequestRecord(token: id, redaction: redaction.rawValue))
            }
            else {
                callback.onFailure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid ID or RedactionType format"]))
            }
        }
        self.apiClient.get(records: list, callback: callback)
    }
}
