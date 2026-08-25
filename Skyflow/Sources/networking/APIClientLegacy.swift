/*
 * Copyright (c) 2022 Skyflow
*/

// Legacy (v1) contract operations on the shared APIClient.

import Foundation

extension APIClient {
    // Base URL for v1 vault endpoints; legacy callbacks append the vault ID and paths.
    internal var legacyVaultURL: String {
        return vaultURL + "v1/vaults/"
    }

    internal func postAndUpdate(records: [String: Any], callback: Callback, options: ICOptions, contextOptions: ContextOptions) {
        let collectApiCallback = CollectAPICallback(callback: callback, apiClient: self, records: records, options: options, contextOptions: contextOptions)
        self.getAccessToken(callback: collectApiCallback, contextOptions: contextOptions)
    }
    internal func post(records: [String: Any], callback: Callback, options: ICOptions, contextOptions: ContextOptions) {
        let insertApiCallback = InsertAPICallback(callback: callback, apiClient: self, records: records, options: options, contextOptions: contextOptions)
        self.getAccessToken(callback: insertApiCallback, contextOptions: contextOptions)
    }
    internal func constructUpdateRequestBody(records: [String: Any], options: ICOptions) -> [String: Any] {
        var postPayload: [String : Any] = [:]
        var fields: [String: Any] = [:]
        fields["fields"] = records["fields"]
        postPayload["record"] = fields
        postPayload["tokenization"] = options.tokens
        return postPayload
    }

    internal func constructBatchRequestBody(records: [String: Any], options: ICOptions) -> [String: Any] {
        var postPayload: [Any] = []
        var insertTokenPayload: [Any] = []
        for (index, record) in (records["records"] as! [[String: Any]]).enumerated() {
            var temp: [String: Any] = [:]
            temp["fields"] = record["fields"]
            temp["tableName"] = record["table"]
            temp["method"] = "POST"
            temp["quorum"] = true

            if options.tokens {
                var temp2: [String: Any] = [:]
                temp2["method"] = "GET"
                temp2["tableName"] = record["table"]
                temp2["ID"] = "$responses." + String(index) + ".records.0.skyflow_id"
                temp2["tokenization"] = true
                insertTokenPayload.append(temp2)
            }
            if options.upsert != nil {
                let columnName = getUniqueColumn(tableName : temp["tableName"] as! String, upsert: options.upsert!);
                if columnName != "" {
                    temp["upsert"] = columnName;
                }
            }
            postPayload.append(temp)
        }
        return ["records": postPayload + insertTokenPayload]
    }

    internal func getUniqueColumn(tableName: String, upsert: [[String: Any]]) -> String{
        var uniqueColumn = "";
        for currUpsertOption in upsert{
            if(currUpsertOption["table"] as! String == tableName){
                uniqueColumn = currUpsertOption["column"] as! String;
            }
        }
        return uniqueColumn;
    }

    internal func get(records: [RevealRequestRecord], callback: Callback, contextOptions: ContextOptions) {
        let revealApiCallback = RevealAPICallback(callback: callback, apiClient: self, connectionUrl: (legacyVaultURL + vaultID), records: records, contextOptions: contextOptions)
        self.getAccessToken(callback: revealApiCallback, contextOptions: contextOptions)
    }
}

// v1 get/getById wire calls (moved from core: legacy-contract only).
extension APIClient {
    internal func getById(records: [GetByIdRecord], callback: Callback, contextOptions: ContextOptions) {
        let revealByIdApiCallback = RevealByIDAPICallback(callback: callback, apiClient: self, connectionUrl: (legacyVaultURL + vaultID), records: records, contextOptions: contextOptions)
        self.getAccessToken(callback: revealByIdApiCallback, contextOptions: contextOptions)
    }
    internal func getRecord(records: [GetRecord], callback: Callback, getOptions: GetOptions, contextOptions: ContextOptions) {
        let getApiCallback = GetAPICallback(callback: callback, apiClient: self, connectionUrl: (legacyVaultURL + vaultID), records: records, getOptions: getOptions, contextOptions: contextOptions)
        self.getAccessToken(callback: getApiCallback, contextOptions: contextOptions)
    }
}
