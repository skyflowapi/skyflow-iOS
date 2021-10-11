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
        Log.log(logLevel: .INFO, message: .CREATED_ELEMENT, values: [input.label == "" ? "reveal" : input.label], contextOptions: self.skyflow.contextOptions)
        return revealElement
    }

    func reveal(callback: Callback, options: RevealOptions? = RevealOptions()) where T: RevealContainer {
        var errorCode: ErrorCodes?
        Log.log(logLevel: .INFO, message: .VALIDATE_REVEAL_RECORDS, contextOptions: self.skyflow.contextOptions)
        if let element = ConversionHelpers.checkElementsAreMounted(elements: self.revealElements) as? Label {
            let label = element.revealInput.label != "" ? " \(element.revealInput.label)" : ""
            errorCode = .UNMOUNTED_REVEAL_ELEMENT(value: element.revealInput.token)
            callback.onFailure(errorCode!.errorObject)
            return
        }
        for element in self.revealElements {
            if element.getValue().isEmpty {
                errorCode = .EMPTY_TOKEN_ID()
                callback.onFailure(errorCode!.errorObject)
                return
            }
        }
        let revealValueCallback = RevealValueCallback(callback: callback, revealElements: self.revealElements, contextOptions: self.skyflow.contextOptions)
        let records = RevealRequestBody.createRequestBody(elements: self.revealElements)
        // Create GetOptions object from RevealOptions object
//        self.skyflow.detokenize(records: records, options: options, callback: revealValueCallback)
        if let tokens = records["records"] as? [[String: Any]] {
            var list: [RevealRequestRecord] = []
            for token in tokens {
                if let redaction = token["redaction"] as? RedactionType, let id = token["token"] as? String {
                    list.append(RevealRequestRecord(token: id, redaction: redaction.rawValue))
                }
            }
            let logCallback = LogCallback(clientCallback: revealValueCallback, contextOptions: self.skyflow.contextOptions,
                onSuccessHandler: {
                    Log.log(logLevel: .INFO, message: .REVEAL_SUBMIT_SUCCESS, contextOptions: self.skyflow.contextOptions)
                },
                onFailureHandler: {
                }
            )
            self.skyflow.apiClient.get(records: list, callback: logCallback, contextOptions: self.skyflow.contextOptions)
        }
    }
}
