/*
 * Copyright (c) 2026 Skyflow
*/

// Configure SkyflowFlowVault, implementation for SkyflowFlowVault.Configuration

import Foundation
import SkyflowCore

public struct Configuration {
    var vaultID: String
    var vaultURL: String
    var tokenProvider: TokenProvider
    var options: Options?

    public init(vaultID: String = "", vaultURL: String = "", tokenProvider: TokenProvider, options: Options? = Options()) {
        self.vaultID = vaultID
        self.vaultURL = vaultURL
        self.tokenProvider = tokenProvider
        self.options = options
    }
}
