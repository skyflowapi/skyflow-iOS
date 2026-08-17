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

package struct ContextOptions {
    package var logLevel: LogLevel
    package var env: Env
    package var interface: InterfaceName

    package init(logLevel: LogLevel = .ERROR, env: Env = .PROD, interface: InterfaceName = .EMPTY) {
        self.logLevel = logLevel
        self.env = env
        self.interface = interface
    }
}
