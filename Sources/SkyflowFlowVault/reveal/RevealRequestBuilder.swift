/*
 * Copyright (c) 2022 Skyflow
*/

// Builds the FlowDB v2 detokenize request in two stages: gathering the tokens
// from the mounted reveal elements, then assembling the final wire payload.
// Stateless builder: only static functions, never instantiated.

import Foundation

internal class RevealRequestBuilder {
    // Stage 1: gather the tokens from the mounted reveal elements.
    internal static func createRevealRecords(elements: [Label]) -> [String: Any] {
        var payload: [[String: Any]] = []
        for element in elements {
            var entry: [String: Any] = [:]
            entry["token"] = element.revealInput.token
            payload.append(entry)
        }

        return ["records": payload]
    }

    // Stage 2: assemble the final v2 detokenize payload.
    internal static func createDetokenizeRequestBody(vaultID: String, records: [RevealRequestRecord], tokenGroupRedactions: [TokenGroupRedaction]? = nil) -> [String: Any] {
        let tokens = records.map { $0.token }
        var body: [String: Any] = ["vaultID": vaultID, "tokens": tokens]
        if let tokenGroupRedactions = tokenGroupRedactions, !tokenGroupRedactions.isEmpty {
            // Pass through exactly what was collected from the mounted elements, duplicates
            // and all - the API validates tokenGroupRedactions, not the SDK.
            body["tokenGroupRedactions"] = tokenGroupRedactions.map { ["tokenGroupName": $0.tokenGroupName, "redaction": $0.redaction] }
        }
        return body
    }
}
