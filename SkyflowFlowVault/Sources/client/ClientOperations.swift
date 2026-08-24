/*
 * Copyright (c) 2022 Skyflow
*/

// FlowVault (v2) entry points on the shared SkyflowCore Client class.
// The v2 operations live below as further extensions.
// Future enhancements specific to this SDK go in extensions in this target
// without affecting the legacy Skyflow SDK.

import Foundation

public extension Client {
    convenience init(_ skyflowConfig: Configuration) {
        self.init(skyflowConfig.data, sdkName: "SkyflowFlowVault")
    }

    func container<T>(type: T.Type, options: ContainerOptions? = nil) -> Container<T>? {
        return makeContainer(type: type, options: options?.data)
    }

}
