/*
 * Copyright (c) 2022 Skyflow
*/

// Used for generating request body for FlowDB v2 detokenize api call

import Foundation

internal class FlowVaultDetokenizeRequestBody {
    internal static func createRequestBody(vaultID: String, records: [RevealRequestRecord], tokenGroupRedactions: [TokenGroupRedaction]? = nil) -> [String: Any] {
        let tokens = records.map { $0.token }
        var body: [String: Any] = ["vaultID": vaultID, "tokens": tokens]
        if let tokenGroupRedactions = tokenGroupRedactions, !tokenGroupRedactions.isEmpty {
            // Dedupe by tokenGroupName, keeping the last occurrence so explicitly-passed
            // options can override anything derived from individual reveal elements.
            var redactionByGroup: [String: String] = [:]
            var order: [String] = []
            for tgr in tokenGroupRedactions {
                if redactionByGroup[tgr.tokenGroupName] == nil { order.append(tgr.tokenGroupName) }
                redactionByGroup[tgr.tokenGroupName] = tgr.redaction
            }
            body["tokenGroupRedactions"] = order.map { ["tokenGroupName": $0, "redaction": redactionByGroup[$0]!] }
        }
        return body
    }
}
