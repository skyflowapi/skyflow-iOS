/*
 * Copyright (c) 2026 Skyflow
*/

// Implementation of SkyflowFlowVault Client class

import Foundation
import SkyflowCore

public class Client {
    var vaultID: String
    var vaultURL: String
    var tokenProvider: TokenProvider
    var contextOptions: ContextOptions

    public init(_ skyflowConfig: Configuration) {
        self.vaultID = skyflowConfig.vaultID
        self.vaultURL = skyflowConfig.vaultURL
        self.tokenProvider = skyflowConfig.tokenProvider
        self.contextOptions = ContextOptions(logLevel: skyflowConfig.options!.logLevel, env: skyflowConfig.options!.env, interface: .CLIENT)
        Log.info(message: .CLIENT_INITIALIZED, contextOptions: self.contextOptions)
    }

    public func container<T>(type: T.Type, options: ContainerOptions? = nil) -> Container<T>? {
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

    // insert/get/getById/detokenize will be implemented against FlowDB's
    // actual REST contract once it's available.
}
