/*
 * Copyright (c) 2022 Skyflow
*/

// FlowVault implementation of the reveal() operation (v2 detokenize with
// token-group redactions).

import Foundation
public extension Container {
    func create(input: RevealElementInput, options: RevealElementOptions? = RevealElementOptions()) -> Label where T: RevealContainer {
        return makeRevealElement(input: input.data, options: options?.data)
    }
    func reveal(callback: RevealCallback, options: RevealOptions? = RevealOptions()) where T: RevealContainer {
        let (tempContextOptions, preflightError) = CoreRequestValidators.revealPreflight(client: self.skyflow, revealElements: self.revealElements)
        if let preflightError = preflightError {
            return callback.onFailure(preflightError.getErrorObject(contextOptions: tempContextOptions))
        }
        if let redactions = options?.tokenGroupRedactions {
            if let redactionError = RequestValidators.checkTokenGroupRedactions(redactions) {
                callback.onFailure(redactionError.getErrorObject(contextOptions: tempContextOptions))
                return
            }
        }
        let revealValueCallback = RevealValueCallback(callback: callback, revealElements: self.revealElements, contextOptions: tempContextOptions)
        let records = RevealRequestBuilder.createRevealRecords(elements: self.revealElements)

        if let tokens = records["records"] as? [[String: Any]] {
            var list: [RevealRequestRecord] = []
            for token in tokens {
                if let id = token["token"] as? String {
                    list.append(RevealRequestRecord(token: id))
                }
            }
            let logCallback = LogCallback(clientCallback: revealValueCallback, contextOptions: tempContextOptions,
                onSuccessHandler: {
                    Log.info(message: .REVEAL_SUBMIT_SUCCESS, contextOptions: tempContextOptions)
                },
                onFailureHandler: {
                }
            )
            self.skyflow.apiClient.get(records: list, tokenGroupRedactions: options?.tokenGroupRedactions, callback: logCallback, contextOptions: tempContextOptions)
        }
    }
}
