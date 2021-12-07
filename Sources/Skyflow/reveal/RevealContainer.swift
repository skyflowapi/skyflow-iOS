//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 05/08/21.
//

import Foundation

public class RevealContainer: ContainerProtocol {
}

public extension Container {
    func create(input: RevealElementInput, options: RevealElementOptions? = RevealElementOptions()) -> Label where T: RevealContainer {
        let revealElement = Label(input: input, options: options!)
        revealElements.append(revealElement)
        Log.info(message: .CREATED_ELEMENT, values: [input.label == "" ? "reveal" : input.label], contextOptions: self.skyflow.contextOptions)
        return revealElement
    }

    func reveal(callback: Callback, options: RevealOptions? = RevealOptions()) where T: RevealContainer {
        var tempContextOptions = self.skyflow.contextOptions
        tempContextOptions.interface = .REVEAL_CONTAINER
        var errorCode: ErrorCodes?
        Log.info(message: .VALIDATE_REVEAL_RECORDS, contextOptions: tempContextOptions)
        if let element = ConversionHelpers.checkElementsAreMounted(elements: self.revealElements) as? Label {
            let label = element.revealInput.label != "" ? " \(element.revealInput.label)" : ""
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
