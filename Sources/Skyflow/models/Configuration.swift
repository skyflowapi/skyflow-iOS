/*
 * Copyright (c) 2022 Skyflow
*/

// Configure Skyflow, implementation for the Configuration object.
// Contract-identical in both SDKs today; declared per SDK so either product
// can add configuration options independently in the future.

import Foundation

public struct Configuration {
    package var data: BaseConfiguration

    public init(vaultID: String = "", vaultURL: String = "", tokenProvider: TokenProvider, options: Options? = Options()) {
        self.data = BaseConfiguration(vaultID: vaultID, vaultURL: vaultURL, tokenProvider: tokenProvider, options: options)
    }
}
