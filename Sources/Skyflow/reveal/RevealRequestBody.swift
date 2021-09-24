//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 13/08/21.
//

import Foundation

internal class RevealRequestBody {
    internal static func createRequestBody(elements: [Label]) -> [String: Any] {

        var payload: [[String: Any]] = []
        for element in elements {
            var entry: [String: Any] = [:]
            entry["token"] = element.revealInput.token
            entry["redaction"] = element.revealInput.redaction
            payload.append(entry)
        }

        return ["records": payload]
    }
}
