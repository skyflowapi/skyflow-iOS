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
// with both podspecs by scripts/bump_version.sh). Each product stamps its own
// SDK_NAME in initialize(); name and version feed error-message prefixes and
// the sdk_name_version vault metric. The default name matches the legacy
// product so directly constructing Client(_:) still reports correctly there.
package var SDK_NAME = "skyflow-iOS"

package var SDK_VERSION = "1.26.0-beta.1"

var LangAndVersion: String { "iOS SDK v\(SDK_VERSION)" }
