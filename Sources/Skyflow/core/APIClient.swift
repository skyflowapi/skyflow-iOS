//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 20/07/21.
//

import Foundation

internal class APIClient {
    var vaultID: String
    var vaultURL: String
    var tokenProvider: TokenProvider
    var token: String = ""

    internal init(vaultID: String, vaultURL: String, tokenProvider: TokenProvider) {
        self.vaultID = vaultID
        self.vaultURL = vaultURL
        self.tokenProvider = tokenProvider
    }

    internal func isTokenValid() -> Bool {

        if token == "" {
            return false
        }

        var payload64 = token.components(separatedBy: ".")[1]

        while payload64.count % 4 != 0 {
            payload64 += "="
        }

        let payloadData = Data(base64Encoded: payload64,
                               options: .ignoreUnknownCharacters)!

        let json = try! JSONSerialization.jsonObject(with: payloadData, options: []) as! [String: Any]
        let exp = json["exp"] as! Int
        let expDate = Date(timeIntervalSince1970: TimeInterval(exp))

        return expDate.compare(Date()) == .orderedDescending
    }

    internal func getAccessToken(callback: Callback) {
        if !isTokenValid() {
            let tokenApiCallback = TokenAPICallback(callback: callback, apiClient: self)
            tokenProvider.getBearerToken(tokenApiCallback)
        } else {
            callback.onSuccess(token)
        }
    }

    internal func post(records: [String: Any], callback: Callback, options: ICOptions) {
        let collectApiCallback = CollectAPICallback(callback: callback, apiClient: self, records: records, options: options)
        self.getAccessToken(callback: collectApiCallback)
    }

    internal func constructBatchRequestBody(records: [String: Any], options: ICOptions) -> [String: Any] {
        var postPayload: [Any] = []
        var insertTokenPayload: [Any] = []
        for (index, record) in (records["records"] as! [Any]).enumerated() {

            var temp: [String: Any] = [:]
            temp["fields"] = (record as! [String: Any])["fields"]
            temp["tableName"] = (record as! [String: Any])["table"]
            temp["method"] = "POST"
            temp["quorum"] = true
            postPayload.append(temp)

            if options.tokens {
                var temp2: [String: Any] = [:]
                temp2["method"] = "GET"
                temp2["tableName"] = (record as! [String: Any])["table"]
                temp2["ID"] = "$responses." + String(index) + ".records.0.skyflow_id"
                temp2["tokenization"] = true
                insertTokenPayload.append(temp2)
            }
        }
        return ["records": postPayload + insertTokenPayload]
    }

    internal func get(records: [RevealRequestRecord], callback: Callback) {
        let revealApiCallback = RevealApiCallback(callback: callback, apiClient: self, connectionUrl: (vaultURL + vaultID), records: records)
        self.getAccessToken(callback: revealApiCallback)
    }

    internal func getById(records: [GetByIdRecord], callback: Callback) {
        let revealByIdApiCallback = RevealByIDAPICallback(callback: callback, apiClient: self, connectionUrl: (vaultURL + vaultID), records: records)
        self.getAccessToken(callback: revealByIdApiCallback)
    }

}
