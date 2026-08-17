/*
 * Copyright (c) 2022 Skyflow
*/

// FlowVault (v2) contract operations on the shared APIClient.

import Foundation

extension APIClient {
    internal func postAndUpdate(records: [String: Any], callback: Callback, upsert: [UpsertOption]? = nil, contextOptions: ContextOptions) {
        let collectApiCallback = FlowVaultCollectAPICallback(callback: callback, apiClient: self, records: records, upsert: upsert, contextOptions: contextOptions)
        self.getAccessToken(callback: collectApiCallback, contextOptions: contextOptions)
    }
    internal func post(records: [String: Any], callback: Callback, upsert: [UpsertOption]? = nil, contextOptions: ContextOptions) {
        let insertApiCallback = FlowVaultCollectAPICallback(callback: callback, apiClient: self, records: records, upsert: upsert, contextOptions: contextOptions)
        self.getAccessToken(callback: insertApiCallback, contextOptions: contextOptions)
    }

    internal func get(records: [RevealRequestRecord], tokenGroupRedactions: [TokenGroupRedaction]? = nil, callback: Callback, contextOptions: ContextOptions) {
        let revealApiCallback = FlowVaultRevealAPICallback(callback: callback, apiClient: self, connectionUrl: (vaultURL + "v2/tokens/detokenize"), records: records, tokenGroupRedactions: tokenGroupRedactions, contextOptions: contextOptions)
        self.getAccessToken(callback: revealApiCallback, contextOptions: contextOptions)
    }
}
