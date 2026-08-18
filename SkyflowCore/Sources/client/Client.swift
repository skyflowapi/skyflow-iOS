/*
 * Copyright (c) 2022 Skyflow
*/

// The one shared Client class, used by both SDK products. It holds shared
// state, container creation, and validation helpers. Each SDK adds its own
// public convenience init (taking that SDK's Configuration) and its contract's
// operations (insert/detokenize/get/getById, ...) via extensions in its own
// target. Applications construct it only through an SDK's convenience init;
// the designated init and all members are package-visible only.

import Foundation

public class Client {
    package var vaultID: String
    package var apiClient: APIClient
    // Normalized base vault URL (always ends with "/"). Empty configuration input
    // normalizes to "/" — SDK extensions use that to detect a missing vault URL.
    package var vaultURL: String
    package var contextOptions: ContextOptions
    package var elementLookup: [String: Any] = [:]

    package init(_ skyflowConfig: BaseConfiguration, sdkName: String = "skyflow-iOS") {
        self.vaultID = skyflowConfig.vaultID
        let normalizedBaseURL = skyflowConfig.vaultURL.hasSuffix("/") ? skyflowConfig.vaultURL : skyflowConfig.vaultURL + "/"
        self.vaultURL = normalizedBaseURL
        self.apiClient = APIClient(vaultID: skyflowConfig.vaultID, vaultURL: normalizedBaseURL, tokenProvider: skyflowConfig.tokenProvider)
        self.contextOptions = ContextOptions(logLevel: skyflowConfig.options!.logLevel, env: skyflowConfig.options!.env, interface: .CLIENT, sdkName: sdkName)
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
