//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 19/07/21.
//

public class Skyflow {
    var vaultId: String
    var apiClient: APIClient
    var vaultURL: String
    
    public init(_ skyflowConfig: SkyflowConfiguration){
        self.vaultId = skyflowConfig.vaultId
        self.vaultURL = skyflowConfig.vaultURL
        self.apiClient = APIClient(vaultId: skyflowConfig.vaultId, vaultURL: skyflowConfig.vaultURL, tokenProvider: skyflowConfig.tokenProvider)
    }
    
    public func insert(records: [String: Any], options: InsertOptions? = InsertOptions(), callback: SkyflowCallback){
        self.apiClient.post(records: records, callback: callback, options: options!)
    }
    
    public func container<T>(type: T.Type, options: ContainerOptions?) -> Container<T>? {
        
        if options != nil {
            //Set options
        }
        
        if T.self == CollectContainer.self {
            return Container<T>(skyflow: self)
        }

        return nil
    }
}
