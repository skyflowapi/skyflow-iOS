/*
 * Copyright (c) 2022 Skyflow
*/

//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 07/10/21.
//

import Foundation

public struct ContextOptions {
    public var logLevel: LogLevel
    public var env: Env
    public var interface: InterfaceName

    public init(logLevel: LogLevel = .ERROR, env: Env = .PROD, interface: InterfaceName = .EMPTY) {
        self.logLevel = logLevel
        self.env = env
        self.interface = interface
    }
}
