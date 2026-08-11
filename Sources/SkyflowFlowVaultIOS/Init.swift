/*
 * Copyright (c) 2022 Skyflow
*/

// Initialize the FlowVault SDK, SkyflowFlowVaultIOS.initialize

import Foundation

public func initialize(_ skyflowConfig: Configuration) -> Client {
    SDK_NAME = "skyflow-flowvault-ios"
    return Client(skyflowConfig)
}
