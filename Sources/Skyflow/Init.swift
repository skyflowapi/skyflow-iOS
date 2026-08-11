/*
 * Copyright (c) 2022 Skyflow
*/

// Initialize Skyflow, Skyflow.initialize

import Foundation

public func initialize(_ skyflowConfig: Configuration) -> Client {
    SDK_NAME = "skyflow-iOS"
    return Client(skyflowConfig)
}
