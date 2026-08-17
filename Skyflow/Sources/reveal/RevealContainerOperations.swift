/*
 * Copyright (c) 2022 Skyflow
*/

// Legacy (v1) implementation of the reveal() operation (per-token redaction).

import Foundation

public extension Container {
    func reveal(callback: Callback, options: RevealOptions? = RevealOptions()) where T: RevealContainer {
        var tempContextOptions = self.skyflow.contextOptions
        tempContextOptions.interface = .REVEAL_CONTAINER
        if let errorCode = CoreRequestValidators.checkClientConfig(vaultID: self.skyflow.vaultID, vaultURL: self.skyflow.vaultURL) {
            return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        Log.info(message: .VALIDATE_REVEAL_RECORDS, contextOptions: tempContextOptions)
        if let elementError = CoreRequestValidators.checkRevealElementsPreflight(elements: self.revealElements) {
            callback.onFailure(elementError.getErrorObject(contextOptions: tempContextOptions))
            return
        }
        let revealValueCallback = RevealValueCallback(callback: callback, revealElements: self.revealElements, contextOptions: tempContextOptions)
        let records = RevealRequestBody.createRequestBody(elements: self.revealElements)

        if let tokens = records["records"] as? [[String: Any]] {
            var list: [RevealRequestRecord] = []
            for token in tokens {
                if let redaction = token["redaction"] as? RedactionType, let id = token["token"] as? String {
                    list.append(RevealRequestRecord(token: id, redaction: redaction.rawValue))
                }
            }
            let logCallback = LogCallback(clientCallback: revealValueCallback, contextOptions: tempContextOptions,
                onSuccessHandler: {
                    Log.info(message: .REVEAL_SUBMIT_SUCCESS, contextOptions: tempContextOptions)
                },
                onFailureHandler: {
                }
            )
            self.skyflow.apiClient.get(records: list, callback: logCallback, contextOptions: tempContextOptions)
        }
    }
}

public extension Container {
    func create(input: RevealElementInput, options: RevealElementOptions? = RevealElementOptions()) -> Label where T: RevealContainer {
        return makeRevealElement(input: input.data, options: options?.data)
    }
}
