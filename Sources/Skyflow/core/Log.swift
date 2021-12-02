//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 07/10/21.
//

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
        print("ERROR: [Skyflow] Interface: \(contextOptions.interface.description) - \(message)")
    }
}
