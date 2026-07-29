/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation

internal class RevealValueCallback: Callback {
    var clientCallback: Callback
    var revealElements: [Label]
    var contextOptions: ContextOptions

    internal init(callback: Callback, revealElements: [Label], contextOptions: ContextOptions) {
        self.clientCallback = callback
        self.revealElements = revealElements
        self.contextOptions = contextOptions
    }

    func onSuccess(_ responseBody: Any) {
        var tokens: [String: String] = [:]

        let responseJson = responseBody as? [String: Any] ?? [:]
        var response: [String: Any] = [:]
        var records: [[String: Any]] = []
        var errors: [[String: Any]] = []

        // Success and per-token failure entries arrive together in one "records" array (matching
        // Collect's convention and the JS SDK's shape), each distinguished by an "error" key.
        if let responseRecords = responseJson["records"] as? [Any] {
            for record in responseRecords {
                guard let dict = record as? [String: Any] else { continue }
                if dict["error"] != nil {
                    errors.append(dict)
                    records.append(dict)
                    continue
                }
                guard let token = dict["token"] as? String else { continue }
                let value = dict["value"] as? String
                tokens[token] = value ?? token

                records.append(dict)
            }
        }

        response["records"] = records
        let tokensToErrors = getTokensToErrors(errors)

        DispatchQueue.main.async {
            for revealElement in self.revealElements {
                if let v = tokens[revealElement.revealInput.token]{
                    revealElement.updateVal(value: v)
                }
            
                let inputToken = revealElement.revealInput.token
                revealElement.hideError()
                
                if let errorMessage = tokensToErrors[inputToken] {
                    revealElement.showError(message: errorMessage)
                } else {
                    Log.info(message: .ELEMENT_REVEALED, values: [revealElement.revealInput.label], contextOptions: self.contextOptions)
                }
            }
        }
        self.clientCallback.onSuccess(response)
    }

    // Reserved for whole-request failures: a genuinely opaque error (can't be parsed as a
    // dictionary at all), or a network/API-level error not scoped to any specific token (no
    // "token" key - e.g. an invalid bearer token, a connection failure). Only PER-TOKEN failures
    // (each tagged with the "token" they belong to) are routed through onSuccess instead, matching
    // Collect's convention of surfacing per-record issues via the record's own "error" field.
    func onFailure(_ error: Any) {
        guard let responseJson = error as? [String: Any] else {
            self.clientCallback.onFailure(error)
            return
        }

        var errors = [] as [[String: Any]]
        if let responseErrors = responseJson["errors"] as? [[String: Any]] {
            errors = responseErrors
        }

        // Not scoped to any specific reveal element - a genuine network/API-level failure, not a
        // per-record issue, so it's delivered via onFailure rather than folded into the records array.
        if let networkError = errors.first(where: { $0["token"] == nil }) {
            DispatchQueue.main.async {
                for revealElement in self.revealElements {
                    revealElement.hideError()
                }
            }
            self.clientCallback.onFailure(networkError["error"] ?? error)
            return
        }

        var tokens: [String: String] = [:]
        var records: [[String: Any]] = []

        if let responseRecords = responseJson["records"] as? [Any] {
            for record in responseRecords {
                guard let dict = record as? [String: Any], let token = dict["token"] as? String else { continue }
                let value = dict["value"] as? String
                tokens[token] = value ?? token

                records.append(dict)
            }
        }

        // Each entry's "error" arrives as an NSError here (built internally, not deserialized from
        // JSON) - convert to a plain message string so it matches the "records" array's normal
        // shape (each entry's "error" is always a String, whether from onSuccess or here).
        let stringifiedErrors = errors.map { entry -> [String: Any] in
            var updated = entry
            if let nsError = entry["error"] as? NSError {
                updated["error"] = nsError.localizedDescription
            }
            return updated
        }
        records.append(contentsOf: stringifiedErrors)

        let tokensToErrors = getTokensToErrors(errors)

        DispatchQueue.main.async {
            for revealElement in self.revealElements {
                if let v = tokens[revealElement.revealInput.token]{
                    revealElement.updateVal(value: v)
                }

                let inputToken = revealElement.revealInput.token
                revealElement.hideError()
                if let errorMessage = tokensToErrors[inputToken] {
                    revealElement.showError(message: errorMessage)
                }
            }
        }
        self.clientCallback.onSuccess(["records": records])
    }

    func getTokensToErrors(_ errors: [[String: Any]]?) -> [String: String] {
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
}
