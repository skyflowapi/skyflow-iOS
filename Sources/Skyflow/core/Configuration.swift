/*
 * Copyright (c) 2022 Skyflow
 */

import Foundation

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
