/*
 * Copyright (c) 2022 Skyflow
*/

// Initialize Skyflow, Skyflow.initialize

import Foundation

/**
Initializes the Skyflow client.

- Parameters:
    - skyflowConfig: Configuration for the Skyflow client.

- Returns: Returns an instance of the Skyflow client.
*/
public func initialize(_ skyflowConfig: Configuration) -> Client {
    return Client(skyflowConfig)
}
