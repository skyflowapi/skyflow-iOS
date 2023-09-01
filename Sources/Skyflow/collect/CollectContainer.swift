/*
 * Copyright (c) 2022 Skyflow
*/

// Implementation of Container Interface for Collect the records

import Foundation
import UIKit

/// Wraps all Collect Elements.
public class CollectContainer: ContainerProtocol {}

public extension Container {

    /**
    Creates a Collect Element.

    - Parameters:
        - input: Collect Element input.
        - options: Collect Element options.

    - Returns: Returns the Collect Element.
    */
     func create(input: CollectElementInput, options: CollectElementOptions? = CollectElementOptions()) -> TextField where T: CollectContainer {
        var tempContextOptions = self.skyflow.contextOptions
        tempContextOptions.interface = .COLLECT_CONTAINER
        let skyflowElement = TextField(input: input, options: options!, contextOptions: tempContextOptions)
        elements.append(skyflowElement)
        let uuid = NSUUID().uuidString
        self.skyflow.elementLookup[uuid] = skyflowElement
        skyflowElement.uuid = uuid
        Log.info(message: .CREATED_ELEMENT, values: [input.label == "" ? "collect" : input.label], contextOptions: tempContextOptions)
        return skyflowElement
    }

    /**
    Collects the data and sends it to the vault.

    - Parameters:
        - callback: Implementation of Skyflow.Callback.
        - options: Collects the data and sends it to the vault.
    */
    func collect(callback: Callback, options: CollectOptions? = CollectOptions()) where T: CollectContainer {
        var tempContextOptions = self.skyflow.contextOptions
        tempContextOptions.interface = .COLLECT_CONTAINER
        if self.skyflow.vaultID.isEmpty {
            let errorCode = ErrorCodes.EMPTY_VAULT_ID()
            return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        if self.skyflow.vaultURL == "/v1/vaults/"  {
            let errorCode = ErrorCodes.EMPTY_VAULT_URL()
            return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        var errors = ""
        var errorCode: ErrorCodes?
        Log.info(message: .VALIDATE_COLLECT_RECORDS, contextOptions: tempContextOptions)

        for element in self.elements {
            errorCode = checkElement(element: element)
            if errorCode != nil {
                callback.onFailure(errorCode!.getErrorObject(contextOptions: tempContextOptions))
                return
            }


            let state = element.getState()
            let error = state["validationError"]
            if (state["isRequired"] as! Bool) && (state["isEmpty"] as! Bool) {
                errors += element.columnName + " is empty" + "\n"
                element.updateErrorMessage()
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
                errorCode = .MISSING_RECORDS_IN_ADDITIONAL_FIELDS()
                return callback.onFailure(errorCode!.getErrorObject(contextOptions: tempContextOptions))
            }
            if let additionalFieldEntries = options?.additionalFields!["records"] as? [[String: Any]] {
                if additionalFieldEntries.isEmpty {
                    errorCode = .EMPTY_RECORDS_OBJECT()
                    return callback.onFailure(errorCode!.getErrorObject(contextOptions: tempContextOptions))
                }
                for record in additionalFieldEntries {
                    errorCode = checkRecord(record: record)
                    if errorCode != nil {
                        return callback.onFailure(errorCode!.getErrorObject(contextOptions: tempContextOptions))
                    }
                }
            } else {
                errorCode = .INVALID_RECORDS_TYPE()
                callback.onFailure(errorCode!.getErrorObject(contextOptions: tempContextOptions))
                return
            }
        }
        let records = CollectRequestBody.createRequestBody(elements: self.elements, additionalFields: options?.additionalFields, callback: callback, contextOptions: tempContextOptions)
        let icOptions = ICOptions(tokens: options!.tokens, additionalFields: options?.additionalFields, upsert: options?.upsert, callback: callback, contextOptions: tempContextOptions)
        if options?.upsert != nil {
            if icOptions.validateUpsert() {
                return;
            }
        }
        if records != nil {
            let logCallback = LogCallback(clientCallback: callback, contextOptions: self.skyflow.contextOptions,
                onSuccessHandler: {
                    Log.info(message: .COLLECT_SUBMIT_SUCCESS, contextOptions: tempContextOptions)
                },
                onFailureHandler: {
                }
            )
            self.skyflow.apiClient.post(records: records!, callback: logCallback, options: icOptions, contextOptions: tempContextOptions)
        }
    }

    private func checkElement(element: TextField) -> ErrorCodes? {
        if element.collectInput.table.isEmpty {
            return .EMPTY_TABLE_NAME_IN_COLLECT(value: element.collectInput.type.name)
        }
        if element.collectInput.column.isEmpty {
            return .EMPTY_COLUMN_NAME_IN_COLLECT(value: element.collectInput.type.name)
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
        if (record["table"] as? String == "") {
            return .EMPTY_TABLE_NAME()
        }
        if record["fields"] == nil {
            return .FIELDS_KEY_ERROR()
        }
        if !(record["fields"] is [String: Any]) {
            return .INVALID_FIELDS_TYPE()
        }
        let fields = record["fields"] as! [String: Any]
        if (fields.isEmpty){
            return .EMPTY_FIELDS_KEY()
        }

        return nil
    }
}
