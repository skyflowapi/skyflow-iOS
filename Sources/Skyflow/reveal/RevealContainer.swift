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
        return revealElement
    }

    func reveal(callback: Callback, options: RevealOptions? = RevealOptions()) where T: RevealContainer {
        var errorCode: ErrorCodes?
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
        let revealValueCallback = RevealValueCallback(callback: callback, revealElements: self.revealElements)
        let records = RevealRequestBody.createRequestBody(elements: self.revealElements)
        // Create GetOptions object from RevealOptions object
        self.skyflow.detokenize(records: records, options: options, callback: revealValueCallback)
    }
}
