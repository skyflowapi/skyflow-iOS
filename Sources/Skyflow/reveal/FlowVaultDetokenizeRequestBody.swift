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
            body["tokenGroupRedactions"] = tokenGroupRedactions.map { ["tokenGroupName": $0.tokenGroupName, "redaction": $0.redaction] }
        }
        return body
    }
}
