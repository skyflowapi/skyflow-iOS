/*
 * Copyright (c) 2026 Skyflow
*/

// Placeholder used by collect()/reveal() until they're implemented against
// FlowDB's actual REST contract.

import Foundation

func notImplementedError(_ operation: String) -> NSError {
    return NSError(domain: "SkyflowFlowVault", code: 501, userInfo: [
        NSLocalizedDescriptionKey: "\(operation) is not yet implemented for FlowDB."
    ])
}
