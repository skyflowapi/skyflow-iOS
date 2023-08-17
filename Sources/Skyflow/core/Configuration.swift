/*
 * Copyright (c) 2022 Skyflow
*/

// Configure Skyflow, implementation for Skyflow.Configuration

import Foundation

/// Configuration for the Skyflow client.
public struct Configuration {
    var vaultID: String
    var vaultURL: String
    var tokenProvider: TokenProvider
    var options: Options?

    /**
    This is the description for init method.

    - Parameters:
        - vaultID: ID of the vault to connect to.
        - vaultURL: URL of the vault to connect to.
        - tokenProvider: An implementation of the token provider interface.
        - options: Additional options for configuration.
    */
    public init(vaultID: String = "", vaultURL: String = "", tokenProvider: TokenProvider, options: Options? = Options()) {
        self.vaultID = vaultID
        self.vaultURL = vaultURL
        self.tokenProvider = tokenProvider
        self.options = options
    }
}
