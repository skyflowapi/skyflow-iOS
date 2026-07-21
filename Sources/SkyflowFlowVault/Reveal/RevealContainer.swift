/*
 * Copyright (c) 2026 Skyflow
*/

/*
 * Implementation of Reveal container which helps in creating
 * the reveal element, revealing the tokenized or redacted text
 */

import Foundation
import SkyflowCore

public extension Container {
    func create(input: RevealElementInput, options: RevealElementOptions? = RevealElementOptions()) -> Label where T: RevealContainer {
        var tempContextOptions = self.skyflow.contextOptions
        tempContextOptions.interface = .REVEAL_CONTAINER
        let revealElement = Label(input: input, options: options!)
        revealElements.append(revealElement)
        let uuid = NSUUID().uuidString
        revealElement.uuid = uuid
        Log.info(message: .CREATED_ELEMENT, values: [input.label == "" ? "reveal" : input.label], contextOptions: tempContextOptions)
        return revealElement
    }

    func reveal(callback: Callback, options: RevealOptions? = RevealOptions()) where T: RevealContainer {
        var tempContextOptions = self.skyflow.contextOptions
        tempContextOptions.interface = .REVEAL_CONTAINER
        if self.skyflow.vaultID.isEmpty {
            let errorCode = ErrorCodes.EMPTY_VAULT_ID()
            return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        if self.skyflow.vaultURL.isEmpty {
            let errorCode = ErrorCodes.EMPTY_VAULT_URL()
            return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        Log.info(message: .VALIDATE_REVEAL_RECORDS, contextOptions: tempContextOptions)
        if let errorCode = RevealValidation.validateElements(self.revealElements) {
            callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
            return
        }

        // TODO: build the FlowDB detokenize request and submit it via
        // FlowDB's vault API once that contract is available.
        callback.onFailure(notImplementedError("reveal()"))
    }
}
