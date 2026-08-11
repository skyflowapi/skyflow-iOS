/*
 * Copyright (c) 2022 Skyflow
*/

// Implementation of the Skyflow Client class (FlowVault v2 contract).
// The v2 operations live in ClientOperations.swift as an extension of this
// class. Future enhancements specific to this SDK go here (or in extensions
// in this target) without affecting the legacy Skyflow SDK.

import Foundation

public class Client: ClientBase {
    public init(_ skyflowConfig: Configuration) {
        super.init(skyflowConfig.data)
    }
}

public extension Client {
    func container<T>(type: T.Type, options: ContainerOptions? = nil) -> Container<T>? {
        return makeContainer(type: type, options: options?.data)
    }
}
