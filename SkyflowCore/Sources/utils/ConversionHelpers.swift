//
//  File.swift
//  
//
//  Created by Puneet Verma on 03/10/22.
//

import Foundation

package class ConversionHelpers {
    package static func checkElementsAreMounted(elements: [Any]) -> Any? {
            for element in elements {
                if let label = element as? Label, !label.isMounted() {
                    return label
                } else if let textField = element as? TextField, !textField.isMounted() {
                    return textField
                }
            }
            return nil
        }

    // Recursively rebuilds a [String: Any] dict, descending into nested dictionaries.
    // Shared by both SDKs' collect/get/reveal callbacks to normalize token/hashedData/fields
    // payloads before handing them to the client callback.
    package static func buildFieldsDict(dict: [String: Any]) -> [String: Any] {
        var temp: [String: Any] = [:]
        for (key, val) in dict {
            if let v = val as? [String: Any] {
                temp[key] = buildFieldsDict(dict: v)
            } else {
                temp[key] = val
            }
        }
        return temp
    }

    // Maps each token-scoped reveal failure to a fixed "Invalid Token" message, keyed by token.
    // Shared by both SDKs' RevealValueCallback to build the per-element error lookup.
    package static func getTokensToErrors(_ errors: [[String: Any]]?) -> [String: String] {
        var result = [String: String]()
        if let errorsObj = errors {
            for error in errorsObj {
                if let token = error["token"] as? String {
                    result[token] = "Invalid Token"
                }
            }
        }
        return result
    }

    // Wraps a whole-request reveal/get failure as {"errors": [{"error": errorObject}]}.
    // Shared by both SDKs' Reveal/RevealByID/Get API callbacks. Distinct from
    // Client.callRevealOnFailure(callback:errorObject:), which wraps as
    // {"errors": [errorObject]} (no nested "error" key) for a different call path.
    package static func wrapRevealFailure(errorObject: Error) -> [String: Any] {
        return ["errors": [["error": errorObject]]]
    }
}
