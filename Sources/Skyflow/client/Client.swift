/*
 * Copyright (c) 2022 Skyflow
*/

// Skyflow (legacy v1) entry points on the shared SkyflowCore Client class.
// The v1 operations live in ClientOperations.swift as further extensions.
// Future enhancements specific to this SDK go in extensions in this target
// without affecting the FlowVault SDK.

import Foundation

public extension Client {
    convenience init(_ skyflowConfig: Configuration) {
        self.init(skyflowConfig.data)
    }

    func container<T>(type: T.Type, options: ContainerOptions? = nil) -> Container<T>? {
        return makeContainer(type: type, options: options?.data)
    }
}
