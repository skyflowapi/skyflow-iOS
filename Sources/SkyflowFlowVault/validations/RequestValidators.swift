/*
 * Copyright (c) 2022 Skyflow
*/

// Pre-flight validators for the FlowDB v2 collect flows, shared by the
// collect and composable container operations. Stateless: only static
// functions, never instantiated.
// Contract-agnostic validators (checkClientConfig, checkElement,
// checkRevealElements) live in SkyflowCore.CoreRequestValidators.

import Foundation

internal class RequestValidators {
    internal static func checkRecord(record: AdditionalFieldsRecord, index: Int) -> ErrorCodes? {
        if record.tableName.isEmpty {
            return .EMPTY_TABLE_NAME()
        }
        if record.data.isEmpty {
            return .EMPTY_FIELDS_KEY(value: "\(index)")
        }
        return nil
    }

    // Validation of the typed additional fields passed to collect(), shared by
    // the collect and composable container operations.
    internal static func checkAdditionalFields(_ additionalFields: AdditionalFields) -> ErrorCodes? {
        if additionalFields.records.isEmpty {
            return .EMPTY_RECORDS_OBJECT()
        }
        for (index, record) in additionalFields.records.enumerated() {
            if let errorCode = checkRecord(record: record, index: index) {
                return errorCode
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
