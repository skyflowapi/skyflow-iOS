/*
 * Copyright (c) 2022 Skyflow
*/

// Initialize Skyflow, Skyflow.initialize

import Foundation

/**
This is the description for initialize method.

- Parameters:
    - skyflowConfig: This is the description for skyflowConfig parameter.

- Returns: This is the description of what method returns.
*/
public func initialize(_ skyflowConfig: Configuration) -> Client {
    return Client(skyflowConfig)
}
