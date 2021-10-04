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
    func create(input : RevealElementInput, options : RevealElementOptions? = RevealElementOptions()) -> Label where T:RevealContainer {
        let revealElement = Label(input: input, options: options!)
        revealElements.append(revealElement)
        return revealElement
    }
    
    func reveal(callback: Callback, options: RevealOptions? = RevealOptions()) where T:RevealContainer {
        if let element = ConversionHelpers.checkElementsAreMounted(elements: self.revealElements) as? Label {
            let label = element.revealInput.label != "" ? " \(element.revealInput.label)" : ""
            callback.onFailure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Reveal element\(label) is not mounted"]))
            return
        }
        for element in self.revealElements {
            if element.getValue().isEmpty {
                callback.onFailure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Reveal element \(element.revealInput.label) has no token provided"]))
                return
            }
        }
        let revealValueCallback = RevealValueCallback(callback: callback, revealElements: self.revealElements)
        let records = RevealRequestBody.createRequestBody(elements: self.revealElements)
        //Create GetOptions object from RevealOptions object
        self.skyflow.detokenize(records: records, options: options, callback: revealValueCallback)
    }
}

