/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes the options parameter

public struct Options {
    var logLevel: LogLevel
    var env: Env

    public init(logLevel: LogLevel = .ERROR, env: Env = .PROD) {
        self.logLevel = logLevel
        self.env = env
    }
}
