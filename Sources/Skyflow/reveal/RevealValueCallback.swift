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

    func onFailure(_ error: Any) {
        var response: [String: Any] = [:]

        if let responseJson = error as? [String: Any] {
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

            var errors = [] as [[String: Any]]
            if let responseErrors = responseJson["errors"] as? [[String: Any]] {
                errors = responseErrors
            }
            records.append(contentsOf: errors)

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
                    }
                }
            }
        }
        self.clientCallback.onFailure(response)
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
