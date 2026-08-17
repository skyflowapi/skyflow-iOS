/*
 * Copyright (c) 2022 Skyflow
*/

// Legacy (v1) implementation of the collect() operation.

import Foundation
import UIKit

public extension Container {
    func collect(callback: Callback, options: CollectOptions? = CollectOptions()) where T: CollectContainer {
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
            callback.onFailure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: elementsValidation.errors]))
            return
        }
        if let additionalFields = options?.additionalFields {
            if let errorCode = RequestValidators.checkAdditionalFields(additionalFields) {
                return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
            }
        }
        let records = CollectRequestBody.createRequestBody(elements: self.elements, additionalFields: options?.additionalFields, callback: callback, contextOptions: tempContextOptions)
        let icOptions = ICOptions(tokens: options!.tokens, additionalFields: options?.additionalFields, upsert: options?.upsert, callback: callback, contextOptions: tempContextOptions)
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
            self.skyflow.apiClient.postAndUpdate(records: records!, callback: logCallback, options: icOptions, contextOptions: tempContextOptions)
        }
    }
}

public extension Container {
    func create(input: CollectElementInput, options: CollectElementOptions? = CollectElementOptions()) -> TextField where T: CollectContainer {
        return makeCollectElement(input: input.data, options: options?.data)
    }
}
