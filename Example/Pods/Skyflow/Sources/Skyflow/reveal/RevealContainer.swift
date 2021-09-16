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
        
        let revealValueCallback = RevealValueCallback(callback: callback, revealElements: self.revealElements)
        let records = RevealRequestBody.createRequestBody(elements: self.revealElements)
        self.skyflow.get(records: records, options: options, callback: revealValueCallback)
    }
}

