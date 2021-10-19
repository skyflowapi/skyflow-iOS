//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 07/10/21.
//

import Foundation

internal struct ContextOptions {
    var logLevel: LogLevel
    var env: Env

    internal init(logLevel: LogLevel = .ERROR, env: Env = .PROD) {
        self.logLevel = logLevel
        self.env = env
    }
}
