//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 19/07/21.
//

public class SkyflowCollect {
    var vaultId: String
    var apiClient: APIClient
    var workspaceURL: String
    
    public init(vaultId: String, workspaceURL: String, tokenProvider: TokenProvider){
        self.vaultId = vaultId
        self.workspaceURL = workspaceURL
        self.apiClient = APIClient(vaultId: vaultId, workspaceURL: workspaceURL, tokenProvider: tokenProvider)
    }
    
    public func collect(payload: [[String: Any]], callback: APICallback){
        self.apiClient.post(payload: payload, callback: callback)
    }
}
