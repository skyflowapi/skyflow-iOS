/*
 * Copyright (c) 2022 Skyflow
*/

// Implemention of different states of LOGS

import Foundation

package class Log {
    // The tag is contextOptions.logTag, so a log line identifies which SDK emitted it. This
    // matters when an app installs both pods: the tag was hardcoded to "Skyflow" for both,
    // making legacy and FlowVault output indistinguishable. logTag still resolves to "Skyflow"
    // for the legacy SDK, so only FlowVault's output changes.
    package static func debug(message: Message, values: [String] = [], contextOptions: ContextOptions) {
        if contextOptions.logLevel.rawValue < 1 {
            print("DEBUG: [\(contextOptions.logTag)] Interface: \(contextOptions.interface.description) -  \(message.getDescription(values: values))")
        }
    }
    package static func info(message: Message, values: [String] = [], contextOptions: ContextOptions) {
        if contextOptions.logLevel.rawValue < 2 {
            print("INFO: [\(contextOptions.logTag)] Interface: \(contextOptions.interface.description) -  \(message.getDescription(values: values))")
        }
    }
    package static func warn(message: Message, values: [String] = [], contextOptions: ContextOptions) {
        if contextOptions.logLevel.rawValue < 3 {
            print("WARN: [\(contextOptions.logTag)] Interface: \(contextOptions.interface.description) -  \(message.getDescription(values: values))")
        }
    }
    package static func error(message: String, values: [String] = [], contextOptions: ContextOptions) {
        print("ERROR: [\(contextOptions.logTag)]: \(message)")
    }
}
