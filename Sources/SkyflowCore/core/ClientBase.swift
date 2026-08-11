/*
 * Copyright (c) 2022 Skyflow
*/

// Shared base for the Skyflow client. Each SDK product defines its own public
// `Client` subclass where that contract's operations (insert/detokenize/get/
// getById, ...) and any future SDK-specific enhancements live; the base holds
// shared state, container creation, and validation helpers. Applications can
// see the base type name but cannot construct, subclass, or use it (package init/members).

import Foundation

open class ClientBase {
    package var vaultID: String
    package var apiClient: APIClient
    // Normalized base vault URL (always ends with "/"). Empty configuration input
    // normalizes to "/" — SDK extensions use that to detect a missing vault URL.
    package var vaultURL: String
    package var contextOptions: ContextOptions
    package var elementLookup: [String: Any] = [:]

    package init(_ skyflowConfig: BaseConfiguration) {
        self.vaultID = skyflowConfig.vaultID
        let normalizedBaseURL = skyflowConfig.vaultURL.hasSuffix("/") ? skyflowConfig.vaultURL : skyflowConfig.vaultURL + "/"
        self.vaultURL = normalizedBaseURL
        self.apiClient = APIClient(vaultID: skyflowConfig.vaultID, vaultURL: normalizedBaseURL, tokenProvider: skyflowConfig.tokenProvider)
        self.contextOptions = ContextOptions(logLevel: skyflowConfig.options!.logLevel, env: skyflowConfig.options!.env, interface: .CLIENT)
        Log.info(message: .CLIENT_INITIALIZED, contextOptions: self.contextOptions)
    }

    // The public container(type:options:) taking each SDK's ContainerOptions
    // struct is defined per SDK target and forwards here.
    package func makeContainer<T>(type: T.Type, options: BaseContainerOptions? = nil) -> Container<T>? {
        if options != nil {
            // Set options
        }

        if T.self == CollectContainer.self {
            Log.info(message: .COLLECT_CONTAINER_CREATED, contextOptions: self.contextOptions)
            return Container<T>(skyflow: self)
        }

        if T.self == RevealContainer.self {
            Log.info(message: .REVEAL_CONTAINER_CREATED, contextOptions: self.contextOptions)
            return Container<T>(skyflow: self)
        }
        if T.self == ComposableContainer.self {
            return Container<T>(skyflow: self, options: options)
        }
        return nil
    }

    package func callRevealOnFailure(callback: Callback, errorObject: Error) {
        let result = ["errors": [errorObject]]
        callback.onFailure(result)
    }
}

package class LogCallback: Callback {
    package var clientCallback: Callback
    package var contextOptions: ContextOptions
    package var onSuccessHandler: () -> Void
    package var onFailureHandler: () -> Void

    package init(clientCallback: Callback, contextOptions: ContextOptions, onSuccessHandler: @escaping () -> Void, onFailureHandler: @escaping () -> Void) {
        self.clientCallback = clientCallback
        self.contextOptions = contextOptions
        self.onSuccessHandler = onSuccessHandler
        self.onFailureHandler = onFailureHandler
    }

    package func onSuccess(_ responseBody: Any) {
        self.onSuccessHandler()
        clientCallback.onSuccess(responseBody)
    }

    package func onFailure(_ error: Any) {
        self.onFailureHandler()
        clientCallback.onFailure(error)
    }
}
