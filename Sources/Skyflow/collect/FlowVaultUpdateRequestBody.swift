/*
 * Copyright (c) 2022 Skyflow
*/

// Used for generating request body for FlowDB v2 update-by-skyflowID api call

import Foundation

internal class FlowVaultUpdateRequestBody {
    internal static func createRequestBody(vaultID: String, records: [[String: Any]]) -> [String: Any] {
        return ["vaultID": vaultID, "records": records]
    }
}
