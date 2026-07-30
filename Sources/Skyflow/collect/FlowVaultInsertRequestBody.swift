/*
 * Copyright (c) 2022 Skyflow
*/

// Used for generating request body for FlowDB v2 insert api call

import Foundation

internal class FlowVaultInsertRequestBody {
    internal static func createRequestBody(vaultID: String, records: [String: Any], options: FlowVaultICOptions) -> [String: Any] {
        var recordsPayload: [[String: Any]] = []
        for record in (records["records"] as! [[String: Any]]) {
            var temp: [String: Any] = [:]
            temp["data"] = record["fields"]
            if let tableName = record["table"] as? String {
                temp["tableName"] = tableName
                if let upsertOptions = options.upsert, let match = upsertOptions.first(where: { $0.tableName == tableName }) {
                    var upsertPayload: [String: Any] = ["uniqueColumns": match.uniqueColumns]
                    if let updateType = match.updateType {
                        upsertPayload["updateType"] = updateType.rawValue
                    }
                    temp["upsert"] = upsertPayload
                }
            }
            recordsPayload.append(temp)
        }
        return ["vaultID": vaultID, "records": recordsPayload]
    }
}
