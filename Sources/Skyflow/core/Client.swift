//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 19/07/21.
//

public class Client {
    var vaultId: String
    var apiClient: APIClient
    var vaultURL: String
    
    public init(_ skyflowConfig: Configuration){
        self.vaultId = skyflowConfig.vaultId
        self.vaultURL = skyflowConfig.vaultURL
        self.apiClient = APIClient(vaultId: skyflowConfig.vaultId, vaultURL: skyflowConfig.vaultURL, tokenProvider: skyflowConfig.tokenProvider)
    }
    
    public func insert(records: [String: Any], options: InsertOptions? = InsertOptions(), callback: Callback){
        self.apiClient.post(records: records, callback: callback, options: options!)
    }
    
    public func container<T>(type: T.Type, options: ContainerOptions?) -> Container<T>? {
        
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
            list.append(RevealRequestRecord(token: token["id"] as! String, redaction: token["redaction"] as! String))
        }
        self.apiClient.get(records: list, callback: callback)
    }
}
