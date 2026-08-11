/*
 * Copyright (c) 2022 Skyflow
*/

// FlowVault implementation of the composable container's collect() operation.

import Foundation
import UIKit

public extension Container {

    func collect(callback: Callback, options: CollectOptions? = CollectOptions()) where T: ComposableContainer {
            var tempContextOptions = self.skyflow.contextOptions
            tempContextOptions.interface = .COMPOSABLE_CONTAINER
            if self.skyflow.vaultID.isEmpty {
                let errorCode = ErrorCodes.EMPTY_VAULT_ID()
                return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
            }
            if self.skyflow.vaultURL == "/"  {
                let errorCode = ErrorCodes.EMPTY_VAULT_URL()
                return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
            }
            var errors = ""
            var errorCode: ErrorCodes?
            Log.info(message: .VALIDATE_COMPOSABLE_RECORDS, contextOptions: tempContextOptions)

            for element in self.elements {
                errorCode = checkComposableElement(element: element)
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
            if let additionalFields = options?.additionalFields {
                if additionalFields.records.isEmpty {
                    errorCode = .EMPTY_RECORDS_OBJECT()
                    return callback.onFailure(errorCode!.getErrorObject(contextOptions: tempContextOptions))
                }
                for (index, record) in additionalFields.records.enumerated() {
                    errorCode = checkComposableRecord(record: record, index: index)
                    if errorCode != nil {
                        return callback.onFailure(errorCode!.getErrorObject(contextOptions: tempContextOptions))
                    }
                }
            }
            let records = FlowVaultCollectRequestBody.createRequestBody(elements: self.elements, additionalFields: options?.additionalFields, callback: callback, contextOptions: tempContextOptions)
            let icOptions = FlowVaultICOptions(additionalFields: options?.additionalFields, upsert: options?.upsert, callback: callback, contextOptions: tempContextOptions)
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
                let cvvMap = CVVTokenReplacer.captureCVVMap(elements: self.elements)
                let cvvMaskingCallback = CVVMaskingCallback(cvvMap: cvvMap, wrapping: logCallback)
                self.skyflow.apiClient.postAndUpdate(records: records!, callback: cvvMaskingCallback, options: icOptions, contextOptions: tempContextOptions)
            }
    }

        private func checkComposableElement(element: TextField) -> ErrorCodes? {
            if element.collectInput.tableName.isEmpty {
                return .EMPTY_TABLE_NAME_IN_COLLECT()
            }
            if element.collectInput.column.isEmpty {
                return .EMPTY_COLUMN_NAME_IN_COLLECT()
            }
            if !element.isMounted() {
                return .UNMOUNTED_COLLECT_ELEMENT(value: element.collectInput.column)
            }

            return nil
        }

    private func checkComposableRecord(record: AdditionalFieldsRecord, index: Int) -> ErrorCodes? {
        if record.tableName.isEmpty {
            return .EMPTY_TABLE_NAME()
        }
        if record.data.isEmpty {
            return .EMPTY_FIELDS_KEY(value: "\(index)")
        }
        return nil
    }
}

public extension Container {
    func create(input: CollectElementInput, options: CollectElementOptions? = CollectElementOptions()) -> TextField where T: ComposableContainer {
        return makeComposableElement(input: input.data, options: options?.data)
    }
}
