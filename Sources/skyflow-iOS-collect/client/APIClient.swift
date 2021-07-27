//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 20/07/21.
//

import Foundation

internal class APIClient {
    var vaultId: String
    var workspaceURL: String
    var tokenProvider: TokenProvider
    var token: String = ""
    
    internal init(vaultId: String, workspaceURL: String, tokenProvider: TokenProvider) {
        self.vaultId = vaultId
        self.workspaceURL = workspaceURL
        self.tokenProvider = tokenProvider
    }
    
    internal func isTokenValid() -> Bool{
        
        if token == "" {
            return false
        }
        
        var payload64 = token.components(separatedBy: ".")[1]

        while payload64.count % 4 != 0 {
            payload64 += "="
        }

        let payloadData = Data(base64Encoded: payload64,
                               options:.ignoreUnknownCharacters)!
        
        let json = try! JSONSerialization.jsonObject(with: payloadData, options: []) as! [String:Any]
        let exp = json["exp"] as! Int
        let expDate = Date(timeIntervalSince1970: TimeInterval(exp))
        
        return expDate.compare(Date()) == .orderedDescending
    }
    
    internal func getAccessToken(callback: APICallback) {
        if !isTokenValid() {
            let tokenApiCallback = TokenAPICallback(callback: callback, apiClient: self)
            tokenProvider.getAccessToken(tokenApiCallback)
        }
        else{
            callback.onSuccess(token)
        }
    }
    
    internal func post(payload: [[String: Any]], callback: APICallback){
        let postApiCallback = PostAPICallback(callback: callback, apiClient: self, payload: payload)
        self.getAccessToken(callback: postApiCallback)
    }
    
    internal func constructBatchRequestBody(payload: [[String: Any]]) -> [Any]{
        var postPayload:[Any] = []
        var insertTokenPayload:[Any] = []
        for (index,record) in payload.enumerated(){
            var temp:[String: Any] = [:]
            temp = record
            temp["method"] = "POST"
            temp["quorum"] = true
            postPayload.append(temp)
            var temp2:[String: Any] = [:]
            temp2["method"] = "GET"
            temp2["tableName"] = record["tableName"]
            temp2["ID"] = "$responses." + String(index) + ".records.0.skyflow_id"
            temp2["tokenization"] = true
            insertTokenPayload.append(temp2)
        }
        return postPayload + insertTokenPayload
    }
    
}
