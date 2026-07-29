/*
 * Copyright (c) 2022 Skyflow
*/

/*
 * Implementation of Reveal container which helps in creating
 * the reveal element, revealing the tokenized or redacted text
 */

import Foundation

public class RevealContainer: ContainerProtocol {
}

public extension Container {
    func create(input: RevealElementInput, options: RevealElementOptions? = RevealElementOptions()) -> Label where T: RevealContainer {
        var tempContextOptions = self.skyflow.contextOptions
        tempContextOptions.interface = .REVEAL_CONTAINER
        let revealElement = Label(input: input, options: options!)
        revealElements.append(revealElement)
        let uuid = NSUUID().uuidString
        self.skyflow.elementLookup[uuid] = revealElement
        revealElement.uuid = uuid
        Log.info(message: .CREATED_ELEMENT, values: [input.label == "" ? "reveal" : input.label], contextOptions: tempContextOptions)
        return revealElement
    }

    func reveal(callback: RevealCallback, options: RevealOptions? = RevealOptions()) where T: RevealContainer {
        var tempContextOptions = self.skyflow.contextOptions
        tempContextOptions.interface = .REVEAL_CONTAINER
        if self.skyflow.vaultID.isEmpty {
            let errorCode = ErrorCodes.EMPTY_VAULT_ID()
            return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        if self.skyflow.vaultURL == "/v2/vaults/"  {
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
                if let id = token["token"] as? String {
                    list.append(RevealRequestRecord(token: id))
                }
            }
            var tokenGroupRedactions: [TokenGroupRedaction] = []
            for element in self.revealElements {
                if let tokenGroupName = element.revealInput.tokenGroupName, let redaction = element.revealInput.redaction {
                    tokenGroupRedactions.append(TokenGroupRedaction(tokenGroupName: tokenGroupName, redaction: redaction))
                }
            }
            let logCallback = LogCallback(clientCallback: revealValueCallback, contextOptions: tempContextOptions,
                onSuccessHandler: {
                    Log.info(message: .REVEAL_SUBMIT_SUCCESS, contextOptions: tempContextOptions)
                },
                onFailureHandler: {
                }
            )
            self.skyflow.apiClient.get(records: list, tokenGroupRedactions: tokenGroupRedactions.isEmpty ? nil : tokenGroupRedactions, callback: logCallback, contextOptions: tempContextOptions)
        }
    }
}
