/*
 * Copyright (c) 2026 Skyflow
*/

// Initialize SkyflowFlowVault, SkyflowFlowVault.initialize

import Foundation
import SkyflowCore

public func initialize(_ skyflowConfig: Configuration) -> Client {
    return Client(skyflowConfig)
}
