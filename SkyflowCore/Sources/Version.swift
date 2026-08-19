/*
 * Copyright (c) 2022 Skyflow
*/

//
//  File.swift
//
//
//  Created by Bharti Sagar on 19/05/23.
//

import Foundation

// Both SDK products share this version (single source of truth, kept in sync
// with both podspecs by scripts/bump_version.sh). Version feeds error-message
// prefixes. The per-instance SDK name (for the sdk_name_version vault metric)
// lives on ContextOptions.sdkName instead of here, so that both SDKs
// coexisting in one app process each report their own identity correctly.
package var SDK_VERSION = "1.26.0-beta.1-dev.6c9239a"

var LangAndVersion: String { "iOS SDK v\(SDK_VERSION)" }
