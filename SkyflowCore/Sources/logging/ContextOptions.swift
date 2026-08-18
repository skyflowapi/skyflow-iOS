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
    // Which SDK product created the Client this ContextOptions belongs to - feeds the
    // sdk_name_version vault metric. Per-instance (not a shared global) so that both SDKs
    // coexisting in one app process each report their own identity correctly.
    package var sdkName: String

    package init(logLevel: LogLevel = .ERROR, env: Env = .PROD, interface: InterfaceName = .EMPTY, sdkName: String = "skyflow-iOS") {
        self.logLevel = logLevel
        self.env = env
        self.interface = interface
        self.sdkName = sdkName
    }
}
