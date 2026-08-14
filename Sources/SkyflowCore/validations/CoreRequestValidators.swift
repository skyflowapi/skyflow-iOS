/*
 * Copyright (c) 2022 Skyflow
*/

// Pre-flight request validators shared by both SDKs, used by the client-level
// and container operations. Contract-specific validators stay in each SDK's
// own RequestValidators. Stateless: only static functions, never instantiated.
// Validators compute and return the error; the call sites own delivering the
// failure to their callback.

import Foundation

package class CoreRequestValidators {
    // Guards shared by every operation: the client must have been configured
    // with a vault ID and URL. (An empty vaultURL becomes "/" in SkyflowCore.Client.)
    package static func checkClientConfig(vaultID: String, vaultURL: String) -> ErrorCodes? {
        if vaultID.isEmpty {
            return .EMPTY_VAULT_ID()
        }
        if vaultURL == "/" {
            return .EMPTY_VAULT_URL()
        }
        return nil
    }

    package static func checkElement(element: TextField) -> ErrorCodes? {
        if element.collectInput.tableName.isEmpty {
            return .EMPTY_TABLE_NAME_IN_COLLECT()
        }
        if element.collectInput.column.isEmpty {
            return .EMPTY_COLUMN_NAME_IN_COLLECT()
        }
        if !element.isMounted() {
            return .UNMOUNTED_COLLECT_ELEMENT(value: element.collectInput.column)
        }

        return nil
    }

    package static func checkRevealElements(elements: [Label]) -> ErrorCodes? {
        for element in elements {
            if element.errorTriggered {
                return .ERROR_TRIGGERED(value: element.triggeredErrorMessage)
            }
            if element.getToken().isEmpty {
                return .EMPTY_TOKEN_ID()
            }
        }
        return nil
    }
}
