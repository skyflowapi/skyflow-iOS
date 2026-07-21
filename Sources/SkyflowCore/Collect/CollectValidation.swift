/*
 * Copyright (c) 2026 Skyflow
*/

// Shared element-level validation used by both Collect and Composable
// containers, across all backends - identical regardless of which vault
// API the elements will eventually be submitted to.

import Foundation

public enum CollectValidation {
    public static func checkElement(_ element: TextField) -> ErrorCodes? {
        if element.collectInput.table.isEmpty {
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

    // Returns the first element-level ErrorCodes failure (if any), plus the
    // accumulated per-element validation error string. Mirrors the original
    // inline loop exactly: an element-level error returns immediately, an
    // empty errors string means every element passed input validation.
    public static func validateElements(_ elements: [TextField]) -> (elementError: ErrorCodes?, errors: String) {
        var errors = ""
        for element in elements {
            if let errorCode = checkElement(element) {
                return (errorCode, "")
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
}
