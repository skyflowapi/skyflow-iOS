//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 26/07/21.
//

import Foundation
import UIKit

public class CollectContainer: ContainerProtocol {}

public extension Container {
    
     func create(input : CollectElementInput, options : CollectElementOptions) -> SkyflowElement where T:CollectContainer {
        let skyflowElement = SkyflowTextField(input: input, options: options)
        elements.append(skyflowElement)
        return skyflowElement
    }
    
    func collect(callback: SkyflowCallback, options: InsertOptions? = InsertOptions()) where T:CollectContainer {
        
        var errors = ""
        for element in self.elements
        {
            let state = element.getState()
            let error = state["validationErrors"]
            if((state["isRequired"] as! Bool) && (state["isEmpty"] as! Bool))
            {
                errors += element.columnName+" is empty"+"\n"
            }
            if(!(state["isValid"] as! Bool))
            {
               
                errors += "for " + element.columnName + " " + (error as! String) + "\n"
            }
        }
        if(errors != "")
        {
            callback.onFailure(NSError(domain:"", code:400, userInfo:[NSLocalizedDescriptionKey: errors]))
            return
        }
        let records = CollectRequestBody.createRequestBody(elements: self.elements)
        self.skyflow.insert(records: records, options: options, callback: callback)
    }
}
