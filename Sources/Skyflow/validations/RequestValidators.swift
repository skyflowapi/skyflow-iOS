/*
 * Copyright (c) 2022 Skyflow
*/

// Pre-flight validators for the legacy (v1) request flows, shared by the
// container operations and the client-level operations. Stateless: only
// static functions, never instantiated. Validators compute and return the
// error; the call sites own delivering the failure to their callback.
// Contract-agnostic validators (checkClientConfig, checkElement,
// checkRevealElements) live in SkyflowCore.CoreRequestValidators.

import Foundation

internal class RequestValidators {
    internal static func checkRecord(record: [String: Any], index: Int) -> ErrorCodes? {
        if record["table"] == nil {
            return .TABLE_KEY_ERROR(value: "\(index)")
        }
        if !(record["table"] is String) {
            return .INVALID_TABLE_NAME_TYPE(value: "\(index)")
        }
        if (record["table"] as? String == "") {
            return .EMPTY_TABLE_NAME()
        }
        if record["fields"] == nil {
            return .FIELDS_KEY_ERROR(value: "\(index)")
        }
        if !(record["fields"] is [String: Any]) {
            return .INVALID_FIELDS_TYPE(value: "\(index)")
        }
        let fields = record["fields"] as! [String: Any]
        if (fields.isEmpty){
            return .EMPTY_FIELDS_KEY(value: "\(index)")
        }

        return nil
    }

    internal static func checkDetokenizeRecord(token: [String: Any], index: Int) -> ErrorCodes? {
           if token["redaction"] != nil {
               guard let _ = token["redaction"] as? RedactionType else {
                   return .INVALID_REDACTION_TYPE()
               }
           }
            if token["token"] == nil {
                return .ID_KEY_ERROR()
            } else {
                guard let _ = token["token"] as? String else {
                    return .INVALID_TOKEN_TYPE(value: "\(index)")
                }
            }
        return nil
    }

    internal static func checkGetByIdEntry(entry: [String: Any], index: Int) -> ErrorCodes? {
        if entry.isEmpty {
            return .EMPTY_RECORDS_OBJECT()
        }
        if entry["ids"] == nil {
            return .MISSING_KEY_IDS(value: "\(index)")
        }
        if !(entry["ids"] is [String]) {
            return .INVALID_IDS_TYPE()
        }
        if ((entry["ids"] as? [String])?.count == 0) {
            return .EMPTY_IDS(value: "\(index)")
        }
        let ids = entry["ids"] as! [String]
        for id in ids {
            if (id == "") {
                return .EMPTY_ID_VALUE(value: "\(index)")
            }
        }
        if entry["table"] == nil {
            return .TABLE_KEY_ERROR(value: "\(index)")
        }
        if !(entry["table"] is String) {
            return .INVALID_TABLE_NAME_TYPE(value: "\(index)")
        }
        if ((entry["table"] as? String) == "") {
            return .EMPTY_TABLE_NAME()
        }
        if entry["redaction"] == nil {
            return .REDACTION_KEY_ERROR(value: "\(index)")
        }
        if (entry["redaction"] as? RedactionType) != nil {
            return nil
        } else {
            return .INVALID_REDACTION_TYPE()
        }
    }

    internal static func checkUpsertOptions(_ upsert: [[String: Any]]) -> ErrorCodes? {
        if upsert.count == 0 {
            return .UPSERT_OPTION_CANNOT_BE_EMPTY()
        }
        for (index, currUpsertOption) in upsert.enumerated() {
            if currUpsertOption["table"] == nil {
                return .MISSING_TABLE_NAME_IN_USERT_OPTION(value: "\(index)")
            }
            if currUpsertOption["column"] == nil {
                return .MISSING_COLUMN_NAME_IN_USERT_OPTION(value: "\(index)")
            }
            if currUpsertOption["table"] as! String == "" {
                return .TABLE_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(value: "\(index)")
            }
            if currUpsertOption["column"] as! String == "" {
                return .COLUMN_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(value: "\(index)")
            }
        }
        return nil
    }

    // Validation for the v1 get records dictionaries (moved from Client:
    // only the legacy contract exposes the get operation).
    internal static func validateGetRecords(entry: [String: Any], getOptions: GetOptions, index: Int) -> ErrorCodes? {
        if entry.isEmpty {
            return .EMPTY_RECORDS_OBJECT()
        }
        if (entry["ids"] != nil ){
            if !(entry["ids"] is [String]) {
                return .INVALID_IDS_TYPE()
            }
            if ((entry["ids"] as? [String])?.count == 0) {
                return .EMPTY_IDS(value: "\(index)")
            }
            let ids = entry["ids"] as! [String]
            for id in ids {
                if (id == "") {
                    return .EMPTY_ID_VALUE(value: "\(index)")
                }
            }
        }
        if entry["table"] == nil {
            return .TABLE_KEY_ERROR(value: "\(index)")
        }
        if !(entry["table"] is String) {
            return .INVALID_TABLE_NAME_TYPE(value: "\(index)")
        }
        if ((entry["table"] as? String) == "") {
            return .EMPTY_TABLE_NAME()
        }

        if( getOptions.tokens == true ){
            if (entry["columnName"] != nil || entry["columnValues"] != nil){
                return .TOKENS_GET_COLUMN_NOT_SUPPPORTED()

            }
            if (entry["redaction"] as? RedactionType) != nil {
                return .REDACTION_WITH_TOKEN_NOT_SUPPORTED()
            }
        } else {
            if entry["redaction"] == nil {
                return .REDACTION_KEY_ERROR(value: "\(index)")
            } else if (entry["redaction"] as? RedactionType) == nil {
                return .INVALID_REDACTION_TYPE()
            }
        }

        if(entry["columnName"] == nil){
            if ((entry["ids"] == nil) && (entry["columnValues"] == nil)){
                return .MISSING_IDS_OR_COLUMN_VALUES_IN_GET()
            }
        } else if (entry["columnName"] != nil && entry["columnValues"] == nil){
            return .MISSING_RECORD_COLUMN_VALUE()
        } else if !(entry["columnName"] is String){
            return .INVALID_COLUMN_NAME(value: "\(index)")
        } else if ((entry["ids"] != nil) && (entry["columnName"] != nil)){
            return .SKYFLOW_IDS_AND_COLUMN_NAME_BOTH_SPECIFIED()
        }
        if (entry["columnValues"] != nil){
            if ((entry["columnValues"] as? [String])?.count == 0) {
                return .EMPTY_RECORD_COLUMN_VALUES(value: "\(index)")
            }
            if !(entry["columnValues"] is [String]) {
                return .INVALID_COLUMN_VALUES_IN_GET()
            }
            if ((entry["columnValues"] as? [String])?.count == 0) {
                return .EMPTY_RECORD_COLUMN_VALUES(value: "\(index)")
            }
            let columnValues = entry["columnValues"] as! [String]
            for columnValue in columnValues {
                if (columnValue == "") {
                    return .EMPTY_COLUMN_VALUE(value: "\(index)")
                }
            }
            if( entry["columnName"] == nil ){
                return .MISSING_COLUMN_NAME()
            } else if((entry["columnName"] as? String) == ""){
                return .EMPTY_COLUMN_NAME()
            }
        }

        return nil
    }
}
