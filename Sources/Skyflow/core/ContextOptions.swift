/*
 * Copyright (c) 2022 Skyflow
 */

import Foundation

internal struct ContextOptions {
    var logLevel: LogLevel
    var env: Env
    var interface: InterfaceName

    internal init(logLevel: LogLevel = .ERROR, env: Env = .PROD, interface: InterfaceName = .EMPTY) {
        self.logLevel = logLevel
        self.env = env
        self.interface = interface
    }
}
