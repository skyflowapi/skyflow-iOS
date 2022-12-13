/*
 * Copyright (c) 2022 Skyflow
 */


import Foundation

// Used for generating request body for reveal api call

internal class RevealRequestBody {
    internal static func createRequestBody(elements: [Label]) -> [String: Any] {
        var payload: [[String: Any]] = []
        for element in elements {
            var entry: [String: Any] = [:]
            entry["token"] = element.revealInput.token
            payload.append(entry)
        }

        return ["records": payload]
    }
}
