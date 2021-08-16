//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 13/08/21.
//

import Foundation

internal class RevealRequestBody {
    internal static func createRequestBody(elements: [SkyflowLabel]) -> [String: Any] {
        
        var payload: [[String: String]] = []
        for element in elements {
            var entry: [String: String] = [:]
            entry["id"] = element.revealInput.id
            entry["redaction"] = element.revealInput.redaction
            payload.append(entry)
        }
        
        return ["records": payload]
    }
}
