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
     func create(input: CollectElementInput, options: CollectElementOptions? = CollectElementOptions()) -> TextField where T: CollectContainer {
        let skyflowElement = TextField(input: input, options: options!, contextOptions: self.skyflow.contextOptions)
        elements.append(skyflowElement)
        Log.info(message: .CREATED_ELEMENT, values: [input.label == "" ? "collect" : input.label], contextOptions: self.skyflow.contextOptions)
        return skyflowElement
    }

    func collect(callback: Callback, options: CollectOptions? = CollectOptions()) where T: CollectContainer {
        var errors = ""
        var errorCode: ErrorCodes?
        Log.info(message: .VALIDATE_COLLECT_RECORDS, contextOptions: self.skyflow.contextOptions)

        for element in self.elements {
            errorCode = checkElement(element: element)
            if errorCode != nil {
                callback.onFailure(errorCode!.getErrorObject(contextOptions: self.skyflow.contextOptions))
                return
            }


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
            if options?.additionalFields!["records"] == nil {
                errorCode = .INVALID_RECORDS_TYPE()
                return callback.onFailure(errorCode!.getErrorObject(contextOptions: self.skyflow.contextOptions))
            }
            if let additionalFieldEntries = options?.additionalFields!["records"] as? [[String: Any]] {
                for record in additionalFieldEntries {
                    errorCode = checkRecord(record: record)
                    if errorCode != nil {
                        return callback.onFailure(errorCode?.getErrorObject(contextOptions: self.skyflow.contextOptions))
                    }
                }
            } else {
                errorCode = .MISSING_RECORDS_ARRAY()
                callback.onFailure(errorCode!.getErrorObject(contextOptions: self.skyflow.contextOptions))
                return
            }
        }
        let records = CollectRequestBody.createRequestBody(elements: self.elements, additionalFields: options?.additionalFields, callback: callback, contextOptions: self.skyflow.contextOptions)
        let icOptions = ICOptions(tokens: options!.tokens, additionalFields: options?.additionalFields)

        if records != nil {
            let logCallback = LogCallback(clientCallback: callback, contextOptions: self.skyflow.contextOptions,
                onSuccessHandler: {
                    Log.info(message: .COLLECT_SUBMIT_SUCCESS, contextOptions: self.skyflow.contextOptions)
                },
                onFailureHandler: {
                }
            )
            self.skyflow.apiClient.post(records: records!, callback: logCallback, options: icOptions, contextOptions: self.skyflow.contextOptions)
        }
    }

    private func checkElement(element: TextField) -> ErrorCodes? {
        if element.collectInput.table.isEmpty {
            let label = element.collectInput.label != "" ? " \(element.collectInput.label)" : ""
            return .EMPTY_TABLE_NAME()
        }
        if element.collectInput.column.isEmpty {
            let label = element.collectInput.label != "" ? " \(element.collectInput.label)" : ""
            return .EMPTY_COLUMN_NAME()
        }
        if !element.isMounted() {
            return .UNMOUNTED_COLLECT_ELEMENT(value: element.collectInput.column)
        }

        return nil
    }

    private func checkRecord(record: [String: Any]) -> ErrorCodes? {
        if record["table"] == nil {
            return .TABLE_KEY_ERROR()
        }
        if !(record["table"] is String) {
            return .INVALID_TABLE_NAME_TYPE()
        }
        if record["fields"] == nil {
            return .FIELDS_KEY_ERROR()
        }
        if !(record["fields"] is [String: Any]) {
            return .INVALID_FIELDS_TYPE()
        }

        return nil
    }
}
