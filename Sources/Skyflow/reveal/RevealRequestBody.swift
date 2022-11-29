/*
 * Copyright (c) 2022 Skyflow
 */

import Foundation

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
