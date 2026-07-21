/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes the options parameter

public struct Options {
    public var logLevel: LogLevel
    public var env: Env

    public init(logLevel: LogLevel = .ERROR, env: Env = .PROD) {
        self.logLevel = logLevel
        self.env = env
    }
}
