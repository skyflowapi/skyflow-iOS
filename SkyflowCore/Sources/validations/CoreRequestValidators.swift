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

    // Element-state validation shared by the collect() and composable collect()
    // operations. Returns the fail-fast element error (if any) plus the
    // accumulated per-element validation messages; the call sites own wrapping
    // the messages in their error type and delivering to their callback.
    // Side effects (updateErrorMessage, resignFirstResponder) happen while
    // iterating, exactly as in the original per-SDK loops.
    package static func validateElementStates(elements: [TextField]) -> (errorCode: ErrorCodes?, errors: String) {
        var errors = ""
        for element in elements {
            let errorCode = checkElement(element: element)
            if errorCode != nil {
                return (errorCode, errors)
            }


            let state = element.getState()
            let error = state["validationError"]
            if (state["isRequired"] as! Bool) && (state["isEmpty"] as! Bool) {
                errors += element.columnName + " is empty" + "\n"
                element.updateErrorMessage()
            }
            if !(state["isValid"] as! Bool) {
                errors += "for " + element.columnName + " " + (error as! String) + "\n"
            }
            if element.isFirstResponder {
                element.resignFirstResponder()
            }
        }
        return (nil, errors)
    }

    // Reveal pre-flight shared by both SDKs' reveal() operations: all elements
    // must be mounted, error-free, and carry a token.
    package static func checkRevealElementsPreflight(elements: [Label]) -> ErrorCodes? {
        if let element = ConversionHelpers.checkElementsAreMounted(elements: elements) as? Label {
            return .UNMOUNTED_REVEAL_ELEMENT(value: element.revealInput.token)
        }
        return checkRevealElements(elements: elements)
    }

    // Shared opening sequence of both SDKs' reveal(): tags the context, checks
    // client config, logs validation start, then validates reveal elements.
    // Returns the tagged contextOptions (for the caller's own subsequent
    // error/log calls) plus any error found - the caller owns delivering the
    // failure to its callback, matching the "validators compute, call sites
    // deliver" convention used throughout this file.
    package static func revealPreflight(client: Client, revealElements: [Label]) -> (contextOptions: ContextOptions, errorCode: ErrorCodes?) {
        var tempContextOptions = client.contextOptions
        tempContextOptions.interface = .REVEAL_CONTAINER
        if let errorCode = checkClientConfig(vaultID: client.vaultID, vaultURL: client.vaultURL) {
            return (tempContextOptions, errorCode)
        }
        Log.info(message: .VALIDATE_REVEAL_RECORDS, contextOptions: tempContextOptions)
        if let elementError = checkRevealElementsPreflight(elements: revealElements) {
            return (tempContextOptions, elementError)
        }
        return (tempContextOptions, nil)
    }

    // Insert record-entry validation shared by both SDKs' client insert()
    // operations. Preserves the original loop's semantics exactly: the last
    // entry's error wins, except an invalid fields type stops the scan.
    package static func checkInsertRecordEntries(_ recordEntries: [[String: Any]]) -> ErrorCodes? {
        var errorCode: ErrorCodes?
        for (index, record) in recordEntries.enumerated() {
            if record["table"] != nil {
                if !(record["table"] is String) {
                    errorCode = .INVALID_TABLE_NAME_TYPE(value: "\(index)")
                } else {
                    if (record["table"] as! String).isEmpty {
                        errorCode = .EMPTY_TABLE_NAME()
                    } else {
                        if record["fields"] != nil {
                            if !(record["fields"] is [String: Any]) {
                                errorCode = .INVALID_FIELDS_TYPE(value: "\(index)")
                                break
                            }
                            let fields = record["fields"] as! [String: Any]
                            if fields.isEmpty {
                                errorCode = .EMPTY_FIELDS_KEY(value: "\(index)")
                            }
                         } else {
                            errorCode = .FIELDS_KEY_ERROR(value: "\(index)")
                         }
                     }
                }
            } else {
                errorCode = .TABLE_KEY_ERROR(value: "\(index)")
            }
        }
        return errorCode
    }
}
