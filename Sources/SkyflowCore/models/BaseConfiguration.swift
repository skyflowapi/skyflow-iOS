/*
 * Copyright (c) 2022 Skyflow
*/

// Shared storage for the client configuration. Each SDK product defines its
// own public `BaseConfiguration` struct exposing that contract's initializer
// (identical in both contracts today); Client consumes this value once at
// initialization and does not retain it.

import Foundation

package struct BaseConfiguration {
    package var vaultID: String
    package var vaultURL: String
    package var tokenProvider: TokenProvider
    package var options: Options?

    package init(vaultID: String = "", vaultURL: String = "", tokenProvider: TokenProvider, options: Options? = Options()) {
        self.vaultID = vaultID
        self.vaultURL = vaultURL
        self.tokenProvider = tokenProvider
        self.options = options
    }
}
