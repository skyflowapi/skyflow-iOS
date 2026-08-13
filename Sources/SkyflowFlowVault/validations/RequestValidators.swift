/*
 * Copyright (c) 2022 Skyflow
*/

// Pre-flight validators for the FlowDB v2 collect flows, shared by the
// collect and composable container operations. Stateless: only static
// functions, never instantiated.

import Foundation

internal class RequestValidators {
    // Guards shared by every operation: the client must have been configured
    // with a vault ID and URL. (An empty vaultURL becomes "/" in ClientBase.)
    internal static func checkClientConfig(vaultID: String, vaultURL: String) -> ErrorCodes? {
        if vaultID.isEmpty {
            return .EMPTY_VAULT_ID()
        }
        if vaultURL == "/" {
            return .EMPTY_VAULT_URL()
        }
        return nil
    }

    internal static func checkElement(element: TextField) -> ErrorCodes? {
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

    internal static func checkRecord(record: AdditionalFieldsRecord, index: Int) -> ErrorCodes? {
        if record.tableName.isEmpty {
            return .EMPTY_TABLE_NAME()
        }
        if record.data.isEmpty {
            return .EMPTY_FIELDS_KEY(value: "\(index)")
        }
        return nil
    }

    internal static func checkRevealElements(elements: [Label]) -> ErrorCodes? {
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

    internal static func checkTokenGroupRedactions(_ redactions: [TokenGroupRedaction]) -> ErrorCodes? {
        for (index, entry) in redactions.enumerated() {
            if entry.tokenGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || entry.redaction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .INVALID_TOKEN_GROUP_REDACTION_ENTRY(value: String(index))
            }
        }
        return nil
    }

    internal static func checkUpsertOptions(_ upsert: [UpsertOption]) -> ErrorCodes? {
        if upsert.count == 0 {
            return .UPSERT_OPTION_CANNOT_BE_EMPTY()
        }
        for (index, currUpsertOption) in upsert.enumerated() {
            if currUpsertOption.tableName == "" {
                return .TABLE_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(value: "\(index)")
            }
            if currUpsertOption.uniqueColumns.isEmpty {
                return .UNIQUE_COLUMNS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(value: "\(index)")
            }
        }
        return nil
    }

    internal static func checkDetokenizeRecord(token: [String: Any], index: Int) -> ErrorCodes? {
        if token["token"] == nil {
            return .ID_KEY_ERROR()
        } else {
            guard let _ = token["token"] as? String else {
                return .INVALID_TOKEN_TYPE(value: "\(index)")
            }
        }
        return nil
    }
}
