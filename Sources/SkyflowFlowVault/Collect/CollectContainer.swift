/*
 * Copyright (c) 2026 Skyflow
*/

// Implementation of Container Interface for Collect the records

import Foundation
import SkyflowCore
import UIKit

public extension Container {
    func create(input: CollectElementInput, options: CollectElementOptions? = CollectElementOptions()) -> TextField where T: CollectContainer {
        var tempContextOptions = self.skyflow.contextOptions
        tempContextOptions.interface = .COLLECT_CONTAINER
        let skyflowElement = TextField(input: input, options: options!, contextOptions: tempContextOptions, elements: elements)
        elements.append(skyflowElement)
        let uuid = NSUUID().uuidString
        skyflowElement.uuid = uuid
        Log.info(message: .CREATED_ELEMENT, values: [input.label == "" ? "collect" : input.label], contextOptions: tempContextOptions)
        return skyflowElement
    }

    func collect(callback: Callback, options: CollectOptions? = CollectOptions()) where T: CollectContainer {
        var tempContextOptions = self.skyflow.contextOptions
        tempContextOptions.interface = .COLLECT_CONTAINER
        if self.skyflow.vaultID.isEmpty {
            let errorCode = ErrorCodes.EMPTY_VAULT_ID()
            return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        if self.skyflow.vaultURL.isEmpty {
            let errorCode = ErrorCodes.EMPTY_VAULT_URL()
            return callback.onFailure(errorCode.getErrorObject(contextOptions: tempContextOptions))
        }
        Log.info(message: .VALIDATE_COLLECT_RECORDS, contextOptions: tempContextOptions)

        let (elementError, errors) = CollectValidation.validateElements(self.elements)
        if let elementError = elementError {
            callback.onFailure(elementError.getErrorObject(contextOptions: tempContextOptions))
            return
        }
        if errors != "" {
            callback.onFailure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: errors]))
            return
        }

        // TODO: build the FlowDB request payload and submit it via FlowDB's
        // vault API once that contract is available.
        callback.onFailure(notImplementedError("collect()"))
    }
}
