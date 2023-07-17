/*
 * Copyright (c) 2022 Skyflow
*/

// Configure Skyflow, implementation for Skyflow.Configuration

import Foundation

/// This is the description for Configuration method.
public struct Configuration {
    var vaultID: String
    var vaultURL: String
    var tokenProvider: TokenProvider
    var options: Options?

    /**
    This is the description for init method.

    - Parameters:
        - vaultID: This is the description for vaultID parameter.
        - vaultURL: This is the description for vaultURL parameter.
        - tokenProvider: This is the description for tokenProvider paramter.
        - options: This is the description for options parameter.
    */
    public init(vaultID: String = "", vaultURL: String = "", tokenProvider: TokenProvider, options: Options? = Options()) {
        self.vaultID = vaultID
        self.vaultURL = vaultURL
        self.tokenProvider = tokenProvider
        self.options = options
    }
}
