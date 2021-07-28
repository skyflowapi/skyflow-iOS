//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 19/07/21.
//

public class Skyflow {
    var vaultId: String
    var apiClient: APIClient
    var workspaceURL: String
    
    public init(vaultId: String, workspaceURL: String, tokenProvider: TokenProvider){
        self.vaultId = vaultId
        self.workspaceURL = workspaceURL
        self.apiClient = APIClient(vaultId: vaultId, workspaceURL: workspaceURL, tokenProvider: tokenProvider)
    }
    
    public func insert(records: [[String: Any]], callback: APICallback){
        self.apiClient.post(records: records, callback: callback)
    }
    
    public func createContainer(containerType: ContainerType, containerOptions: ContainerOptions?) -> CollectContainer {
//        let container = Container.createContainer(skyflow: self, containerType: containerType, containerOptions: containerOptions)
        if containerOptions != nil {
            //Set options
        }
        switch containerType {
            case .collect:
                return CollectContainer(skyflow: self)
            case .reveal:
                return CollectContainer(skyflow: self)
            }
    }
}
