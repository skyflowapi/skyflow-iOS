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
    // Human-facing product name, used for the Log tag and as the prefix on validation error
    // messages. Set only by SDKs that opt in; empty means the legacy Skyflow SDK, whose log tag
    // and error text predate this and must stay byte-identical, so an empty value suppresses the
    // error prefix entirely and falls the log tag back to its original hardcoded value.
    // Kept separate from sdkName because that is a lowercase-hyphenated telemetry key already on
    // the wire in sky-metadata ("skyflow-iOS"), not display text.
    package var productName: String

    // "Skyflow" for the legacy SDK - the value Log hardcoded before productName existed.
    package var logTag: String { productName.isEmpty ? "Skyflow" : productName }

    package init(logLevel: LogLevel = .ERROR, env: Env = .PROD, interface: InterfaceName = .EMPTY,
                 sdkName: String = "skyflow-iOS", productName: String = "") {
        self.logLevel = logLevel
        self.env = env
        self.interface = interface
        self.sdkName = sdkName
        self.productName = productName
    }
}
