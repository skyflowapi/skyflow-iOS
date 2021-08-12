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
    func create(input : RevealElementInput, options : RevealElementOptions) -> RevealElement where T:RevealContainer {
        //       let skyflowElement = SkyflowTextField(input: input, options: options)
        let revealElement = RevealElement(input: input, options: options)
        revealElements.append(revealElement)
        return revealElement
    }
    
    func reveal(callback: SkyflowCallback, options: RevealOptions? = RevealOptions()) where T:RevealContainer {
        
        //TO-DO
    }
}

