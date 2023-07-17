/*
 * Copyright (c) 2022 Skyflow
*/

/// Object that describes the options parameter

public struct Options {
    /// This is the description for logLevel property.
    var logLevel: LogLevel
    /// This is the description for env property.
    var env: Env

    /**
    This is the description for init method.

    - Parameters:
        - logLevel: This is the description for logLevel parameter.
        - env: This is the description for env parameter.
    */
    public init(logLevel: LogLevel = .ERROR, env: Env = .PROD) {
        self.logLevel = logLevel
        self.env = env
    }
}
