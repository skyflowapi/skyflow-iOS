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
     func create(input: CollectElementInput, options: CollectElementOptions? = CollectElementOptions()) -> Element where T: CollectContainer {
        let skyflowElement = TextField(input: input, options: options!)
        elements.append(skyflowElement)
        return skyflowElement
    }

    func collect(callback: Callback, options: CollectOptions? = CollectOptions()) where T: CollectContainer {
        var errors = ""
        for element in self.elements {
            let state = element.getState()
            let error = state["validationErrors"]
            if (state["isRequired"] as! Bool) && (state["isEmpty"] as! Bool) {
                errors += element.columnName + " is empty" + "\n"
            }
            if !(state["isValid"] as! Bool) {
                errors += "for " + element.columnName + " " + (error as! String) + "\n"
            }
            if element.isFirstResponder {
                element.resignFirstResponder()
            }
        }
        if errors != "" {
            callback.onFailure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: errors]))
            return
        }
        if options?.additionalFields != nil {
            if let additionalFieldEntries = options?.additionalFields!["records"] as? [[String: Any]] {
                for record in additionalFieldEntries {
                    if !(record["table"] is String) || !(record["fields"] is [String: Any]) {
                        callback.onFailure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid/Missing table or fields"]))
                        return
                    }
                }
            } else {
                callback.onFailure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "No records array"]))
                return
            }
        }
        let records = CollectRequestBody.createRequestBody(elements: self.elements, additionalFields: options?.additionalFields, callback: callback)
        let icOptions = ICOptions(tokens: options!.tokens, additionalFields: options?.additionalFields)

        if records != nil {
        self.skyflow.apiClient.post(records: records!, callback: callback, options: icOptions)
        }
    }
}
