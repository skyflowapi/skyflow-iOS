/*
 * Copyright (c) 2022 Skyflow
*/

// Legacy (v1) implementation of the reveal() operation (per-token redaction).

import Foundation

public extension Container {
    func reveal(callback: Callback, options: RevealOptions? = RevealOptions()) where T: RevealContainer {
        var tempContextOptions = self.skyflow.contextOptions
        tempContextOptions.interface = .REVEAL_CONTAINER
        if self.skyflow.vaultID.isEmpty {
            let errorCode = ErrorCodes.EMPTY_VAULT_ID()
            return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        if self.skyflow.vaultURL == "/"  {
            let errorCode = ErrorCodes.EMPTY_VAULT_URL()
            return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        var errorCode: ErrorCodes?
        Log.info(message: .VALIDATE_REVEAL_RECORDS, contextOptions: tempContextOptions)
        if let element = ConversionHelpers.checkElementsAreMounted(elements: self.revealElements) as? Label {
            errorCode = .UNMOUNTED_REVEAL_ELEMENT(value: element.revealInput.token)
            callback.onFailure(errorCode!.getErrorObject(contextOptions: tempContextOptions))
            return
        }
        for element in self.revealElements {
            if element.errorTriggered {
                errorCode = .ERROR_TRIGGERED(value: element.triggeredErrorMessage)
                callback.onFailure(errorCode!.getErrorObject(contextOptions: tempContextOptions))
                return
            }
            if element.getToken().isEmpty {
                errorCode = .EMPTY_TOKEN_ID()
                callback.onFailure(errorCode!.getErrorObject(contextOptions: tempContextOptions))
                return
            }
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
