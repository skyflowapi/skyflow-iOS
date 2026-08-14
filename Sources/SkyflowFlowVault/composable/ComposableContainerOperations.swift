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
            if let errorCode = CoreRequestValidators.checkClientConfig(vaultID: self.skyflow.vaultID, vaultURL: self.skyflow.vaultURL) {
                return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
            }
            var errors = ""
            var errorCode: ErrorCodes?
            Log.info(message: .VALIDATE_COMPOSABLE_RECORDS, contextOptions: tempContextOptions)

            for element in self.elements {
                errorCode = CoreRequestValidators.checkElement(element: element)
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
                    errorCode = RequestValidators.checkRecord(record: record, index: index)
                    if errorCode != nil {
                        return callback.onFailure(errorCode!.getErrorObject(contextOptions: tempContextOptions))
                    }
                }
            }
            let records = CollectRequestBuilder.createCollectRecords(elements: self.elements, additionalFields: options?.additionalFields, callback: callback, contextOptions: tempContextOptions)
            if let upsert = options?.upsert {
                if let upsertError = RequestValidators.checkUpsertOptions(upsert) {
                    return callback.onFailure(upsertError.getErrorObject(contextOptions: tempContextOptions))
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
                self.skyflow.apiClient.postAndUpdate(records: records!, callback: cvvMaskingCallback, upsert: options?.upsert, contextOptions: tempContextOptions)
            }
    }
}

public extension Container {
    func create(input: CollectElementInput, options: CollectElementOptions? = CollectElementOptions()) -> TextField where T: ComposableContainer {
        return makeComposableElement(input: input.data, options: options?.data)
    }
}
