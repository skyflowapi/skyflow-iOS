/*
 * Copyright (c) 2022 Skyflow
*/

// Implemention of different states of LOGS

import Foundation

internal class Log {
    internal static func debug(message: Message, values: [String] = [], contextOptions: ContextOptions) {
        if contextOptions.logLevel.rawValue < 1 {
            print("DEBUG: [Skyflow] Interface: \(contextOptions.interface.description) -  \(message.getDescription(values: values))")
        }
    }
    internal static func info(message: Message, values: [String] = [], contextOptions: ContextOptions) {
        if contextOptions.logLevel.rawValue < 2 {
            print("INFO: [Skyflow] Interface: \(contextOptions.interface.description) -  \(message.getDescription(values: values))")
        }
    }
    internal static func warn(message: Message, values: [String] = [], contextOptions: ContextOptions) {
        if contextOptions.logLevel.rawValue < 3 {
            print("WARN: [Skyflow] Interface: \(contextOptions.interface.description) -  \(message.getDescription(values: values))")
        }
    }
    internal static func error(message: String, values: [String] = [], contextOptions: ContextOptions) {
        print("ERROR: [Skyflow]: \(message)")
    }
}
