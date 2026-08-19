/* Copyright (c) 2022 Skyflow
*/

// FlowVault implementation of the collect() operation.

import Foundation

public extension Container {
    func create(input: CollectElementInput, options: CollectElementOptions? = CollectElementOptions()) -> TextField where T: CollectContainer {
        return makeCollectElement(input: input.data, options: options?.data)
    }
    func collect(callback: CollectCallback, options: CollectOptions? = CollectOptions()) where T: CollectContainer {
        var tempContextOptions = self.skyflow.contextOptions
        tempContextOptions.interface = .COLLECT_CONTAINER
        if let errorCode = CoreRequestValidators.checkClientConfig(vaultID: self.skyflow.vaultID, vaultURL: self.skyflow.vaultURL) {
            return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        Log.info(message: .VALIDATE_COLLECT_RECORDS, contextOptions: tempContextOptions)

        let elementsValidation = CoreRequestValidators.validateElementStates(elements: self.elements)
        if let elementErrorCode = elementsValidation.errorCode {
            callback.onFailure(elementErrorCode.getErrorObject(contextOptions: tempContextOptions))
            return
        }
        if elementsValidation.errors != "" {
            callback.onFailure(SkyflowError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: elementsValidation.errors]))
            return
        }
        if let additionalFields = options?.additionalFields {
            if let errorCode = RequestValidators.checkAdditionalFields(additionalFields) {
                return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
            }
        }
        if let upsert = options?.upsert {
            if let upsertError = RequestValidators.checkUpsertOptions(upsert) {
                return callback.onFailure(upsertError.getErrorObject(contextOptions: tempContextOptions))
            }
        }
        let records = CollectRequestBuilder.createCollectRecords(elements: self.elements, additionalFields: options?.additionalFields, callback: callback, contextOptions: tempContextOptions)
        if records != nil {
            let logCallback = LogCallback(clientCallback: callback, contextOptions: tempContextOptions,
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
