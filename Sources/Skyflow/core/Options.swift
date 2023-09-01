/*
 * Copyright (c) 2022 Skyflow
*/

/// Additional configuration for the Skyflow client.

public struct Options {
    /// Log level to apply. 
    var logLevel: LogLevel
    /// Type of environment.
    var env: Env

    /**
    Initializes the Skyflow client.

    - Parameters:
        - logLevel: Log level to apply.
        - env: Type of environment.
    */
    public init(logLevel: LogLevel = .ERROR, env: Env = .PROD) {
        self.logLevel = logLevel
        self.env = env
    }
}
