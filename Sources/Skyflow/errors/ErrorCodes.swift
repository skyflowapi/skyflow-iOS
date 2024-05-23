/*
 * Copyright (c) 2022 Skyflow
*/

// List of all error code

import Foundation

internal enum ErrorCodes: CustomStringConvertible {
    // No message values
    case EMPTY_TABLE_NAME(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Invalid type for 'table' key value in collect element. Specify a value of type string instead.")
    case EMPTY_COMPOSABLE_LAYOUT_ARRAY(code: Int = 400, message: String = "\(LangAndVersion) Mount failed. Layout array is empty in composable container options. Specify a valid layout array.")
    case MISSING_COMPOSABLE_CONTAINER_OPTIONS(code: Int = 400, message: String = "options object is required for composable container.")
    case MISSING_COMPOSABLE_LAYOUT_KEY(code:Int = 400, message: String = "\(LangAndVersion) Mount failed. Layout isn't specified in composable container options. Specify a valid layout.")
    case EMPTY_COLUMN_NAME(code: Int = 400, message: String = "\(LangAndVersion) Validation error. 'column' key cannot be empty. Specify a non-empty value instead.")
    case EMPTY_VAULT_ID(code: Int = 400, message: String = "\(LangAndVersion) Initialization failed. Invalid credentials. Specify a valid 'vaultID'.")
    case EMPTY_VAULT_URL(code: Int = 400, message: String = "\(LangAndVersion) Initialization failed. Invalid credentials. Specify a valid 'vaultURL'.")
    case EMPTY_IDS(code: Int = 400, message: String = "\(LangAndVersion) Validation error. 'ids' key cannot be an array of empty strings in records at index <index>. Specify non-empty values instead.", value: String)
    case EMPTY_ID_VALUE(code: Int = 400, message: String = "\(LangAndVersion) Validation error. 'id' cannot be empty in 'ids' array in 'records' at index <index>. Specify non-empty values instead.", value: String)
    case RECORDS_KEY_ERROR(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Missing 'records' key. Provide a valid 'records' key.")
    case TABLE_KEY_ERROR(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Missing 'table' key in records at index <index>. Provide a valid 'table' key.", value: String)
    case FIELDS_KEY_ERROR(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Missing 'fields' key in records at index <index>. Provide a valid 'fields' key.", value: String)
    case EMPTY_FIELDS_KEY(code: Int = 400, message: String = "\(LangAndVersion) Validation error. 'fields' key not found in records at index <index>. Specify a valid value for 'fields' key.", value: String)
    case EMPTY_TOKEN_ID(code: Int = 400, message: String = "\(LangAndVersion) Validation error. 'token' key cannot be empty for reveal element. Specify a non-empty value instead.")
    case ID_KEY_ERROR(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Missing 'token' key for reveal element. Specify a valid value for token.")
    case REDACTION_KEY_ERROR(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Missing 'redaction' key in records at index <index>. Provide a valid 'redaction' key.", value: String)
    case MISSING_KEY_IDS(code: Int = 404, message: String = "\(LangAndVersion) Validation error. Missing 'ids' key in records at index <index>. Provide a valid 'ids' key.", value: String)
    // New
    case INVALID_TABLE_NAME_TYPE(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Invalid 'table' key in records at index <index>. Specify a value of type string instead.", value: String)
    case INVALID_FIELDS_TYPE(code: Int = 400, message: String = "\(LangAndVersion) Validation error.invaid 'fields' key value in record at index <index>. Specify a value of type array for 'fields' key.", value: String)
    case INVALID_RECORDS_TYPE(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Invalid 'records' key found. Specify a value of type array instead.")
    case INVALID_BEARER_TOKEN_FORMAT(code: Int = 400, message: String = "\(LangAndVersion) Token generated from 'getBearerToken' callback function is invalid. Make sure the implementation of 'getBearerToken' is correct.")
    case MISSING_RECORDS_ARRAY(code: Int = 404, message: String = "\(LangAndVersion) Validation error.'records' key not found in additionalFields. Specify a 'records' key in addtionalFields.")
    case MISSING_RECORDS_IN_ADDITIONAL_FIELDS(code: Int = 404, message: String = "\(LangAndVersion) Validation error.'records' object cannot be empty within additionalFields. Specify a non-empty value instead.")
    case EMPTY_RECORDS_OBJECT(code: Int = 404, message: String = "\(LangAndVersion) Validation error. 'records' key cannot be empty. Provide a non-empty value instead.")
    case MISSING_RECORDS_IN_GETBYID(code: Int = 404, message: String = "\(LangAndVersion) Validation error. 'records' key cannot be empty. Provide a non-empty value instead.")
    case INVALID_TOKEN_TYPE(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Invalid 'token' key in records at index <index>. Specify a value of type string instead.", value: String)
    case INVALID_URL(code: Int = 400, message: String = "\(LangAndVersion) Initialization failed. Invalid credentials. Specify a valid 'vaultURL'.")
    case INVALID_IDS_TYPE(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Invalid 'ids' key found. Specify a value of type array instead.")
    case APIError(code: Int, message: String)

    // Single message value

    case INVALID_REDACTION_TYPE(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Invalid 'redaction' key in records at index <index>. Specify a valid redaction type.")
    case SKYFLOW_IDS_AND_COLUMN_NAME_BOTH_SPECIFIED(code: Int = 400, message: String = "\(LangAndVersion) Validation error. ids and columnName can not be specified together.")
    case MISSING_IDS_OR_COLUMN_VALUES_IN_GET(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Both 'ids' or 'columnValues' keys are missing. Either provide 'ids' or 'columnValues' with 'columnName' to fetch records.")
    case MISSING_RECORD_COLUMN_VALUE(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Column Values is required when Column Name is specified.")
    case MISSING_COLUMN_NAME(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Column Name is required when Column Values are specified.")
    case EMPTY_RECORD_COLUMN_VALUES(code: Int = 400, message: String = "\(LangAndVersion) Validation error. 'columnValues' key cannot be empty in records at index <index>. Specify a non-empty value instead.", value: String)
    case INVALID_COLUMN_VALUES_IN_GET(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Invalid 'columnValues' key found. Specify a value of type array instead.")
    case EMPTY_COLUMN_VALUE(code: Int = 400, message: String = "\(LangAndVersion) Validation error. 'columnValues' key values cannot be empty in records at index <index>. Specify a non-empty value instead.", value: String)
    case REDACTION_WITH_TOKEN_NOT_SUPPORTED(code: Int = 400, message: String = "\(LangAndVersion) Get failed. Redaction cannot be applied when 'tokens' are set to true in get options. Either remove redaction or set 'tokens' to false.")
    case TOKENS_GET_COLUMN_NOT_SUPPPORTED(code: Int = 400, message: String = "\(LangAndVersion) Validation error. 'columnName' and 'columnValues' cannot be used when 'tokens' are set to true in get options. Either set 'tokens' to false or use 'ids' instead.")
    case INVALID_COLUMN_NAME(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Invalid type for 'columnName' key in records at index <index>. Specify a value of type string instead.", value: String)

    case UNMOUNTED_COLLECT_ELEMENT(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Element with column name <COLUMN_NAME> is unmounted", value: String)
    case UNMOUNTED_REVEAL_ELEMENT(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Element with token <TOKEN> is unmounted", value: String)
    case ERROR_TRIGGERED(code: Int = 400, message: String = "<TRIGGERED_ERROR_MESSAGE>", value: String)
    case EMPTY_COLUMN_NAME_IN_COLLECT(code: Int = 400, message: String = "\(LangAndVersion) Validation error. 'column' key cannot be empty. Specify a non-empty value instead.")
    case EMPTY_TABLE_NAME_IN_COLLECT(code: Int = 400, message: String = "\(LangAndVersion) Validation error.'table' key not found in collect element. Specify a valid value for 'table' key.")

    case REGEX_MATCH_FAILED(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Invalid value for 'regex' param found for regex. Provide a valid value regular expression for regex param.")
    // Multiple message values
    // changed
    case DUPLICATE_ELEMENT_FOUND(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Duplicate for column <column> is found for table <table>. Please ensure each column within a record is unique.",values: [String])
    // new
    case DUPLICATE_ADDITIONAL_FIELD_FOUND(code: Int = 400, message: String = "\(LangAndVersion). '<column>' appeared in record in the additional fields. Make sure each column in a record is unique.", value: String)
    case MISSING_TABLE_NAME_IN_USERT_OPTION(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Missing 'table' key in upsert array at index <index>. Provide a valid 'table' key.", value: String)
    case UPSERT_OPTION_CANNOT_BE_EMPTY(code: Int = 400, message: String = "\(LangAndVersion) Validation error. 'upsert' key cannot be an empty array in insert options. Make sure to add atleast one table column object in upsert array.")
    case MISSING_COLUMN_NAME_IN_USERT_OPTION(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Missing 'column' key in upsert array at index <index>. Provide a valid 'column' key.", value: String)
    case COLUMN_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Invalid 'table' key in upsert array at index <index>. Specify a value of type string instead.", value: String)
    case TABLE_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(code: Int = 400, message: String = "\(LangAndVersion) Validation error. Invalid 'table' key in upsert array at index <index>. Specify a value of type string instead.", value: String)
    case MISMATCH_ELEMENT_COUNT_LAYOUT_SUM(code: Int = 400, message: String = "\(LangAndVersion) Mount failed. Invalid layout array values. Make sure all values in the layout array are positive numbers.")
    var code: Int {
        switch self {
            // No Formatting required
            // swiftlint:disable:next line_length
        case .EMPTY_TABLE_NAME(let code, _), .EMPTY_VAULT_ID(let code, _),  .EMPTY_VAULT_URL(let code, _),.RECORDS_KEY_ERROR( let code, _),.EMPTY_TOKEN_ID(let code, _), .ID_KEY_ERROR(let code, _), .INVALID_RECORDS_TYPE(let code, _), .EMPTY_COLUMN_NAME(let code, _), .INVALID_BEARER_TOKEN_FORMAT(let code, _), .MISSING_RECORDS_ARRAY(let code, _), .MISSING_RECORDS_IN_ADDITIONAL_FIELDS(let code, _), .EMPTY_RECORDS_OBJECT(let code, _), .MISSING_RECORDS_IN_GETBYID(let code, _),.INVALID_URL(let code, _), .INVALID_IDS_TYPE(let code, _),.REDACTION_WITH_TOKEN_NOT_SUPPORTED(let code, _), .TOKENS_GET_COLUMN_NOT_SUPPPORTED(let code, _), .MISSING_COLUMN_NAME(let code,_), .UPSERT_OPTION_CANNOT_BE_EMPTY(let code, _),.INVALID_REDACTION_TYPE(let code, _),.EMPTY_COLUMN_NAME_IN_COLLECT(let code, _), .EMPTY_TABLE_NAME_IN_COLLECT(let code, _), .REGEX_MATCH_FAILED(let code, _),.SKYFLOW_IDS_AND_COLUMN_NAME_BOTH_SPECIFIED(let code, _),.MISSING_IDS_OR_COLUMN_VALUES_IN_GET(let code, _), .MISSING_RECORD_COLUMN_VALUE(let code, _), .INVALID_COLUMN_VALUES_IN_GET(let code, _), .EMPTY_COMPOSABLE_LAYOUT_ARRAY(let code, _), .MISSING_COMPOSABLE_LAYOUT_KEY(let code, _), .MISMATCH_ELEMENT_COUNT_LAYOUT_SUM(let code, _),.MISSING_COMPOSABLE_CONTAINER_OPTIONS(code: let code, message: _):
            return code
            // Single value formatting
            // swiftlint:disable:next line_length
            // Multi value formatting
        case  .EMPTY_IDS(let code, _, _), .EMPTY_ID_VALUE(let code, _, _), .TABLE_KEY_ERROR(let code, _, _), .FIELDS_KEY_ERROR(let code, _, _), .EMPTY_FIELDS_KEY(let code, _, _), .REDACTION_KEY_ERROR(let code, _, _), .MISSING_KEY_IDS(let code, _, _), .INVALID_TABLE_NAME_TYPE(let code, _, _), .INVALID_FIELDS_TYPE(let code, _, _), .INVALID_TOKEN_TYPE(let code, _, _), .MISSING_TABLE_NAME_IN_USERT_OPTION(let code, _, _),.MISSING_COLUMN_NAME_IN_USERT_OPTION(let code, _, _), .COLUMN_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(let code, _, _), .TABLE_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(let code, _, _), .APIError(let code, _), .INVALID_COLUMN_NAME(let code, _, _), .UNMOUNTED_COLLECT_ELEMENT(let code, _, _), .UNMOUNTED_REVEAL_ELEMENT(let code, _, _), .ERROR_TRIGGERED(let code, _, _), .DUPLICATE_ADDITIONAL_FIELD_FOUND(let code, _, _), .EMPTY_RECORD_COLUMN_VALUES(code: let code, message: _, value: _), .EMPTY_COLUMN_VALUE(code: let code, message: _, value: _),.DUPLICATE_ELEMENT_FOUND(let code, _, _) :
            return code

        }
    }

    internal var description: String {
        switch self {
            // No Formatting required
            // swiftlint:disable:next line_length
        case .APIError(_, let message), .INVALID_REDACTION_TYPE( _, let message), .EMPTY_COLUMN_NAME_IN_COLLECT( _, let message), .EMPTY_TABLE_NAME_IN_COLLECT( _, let message), .REGEX_MATCH_FAILED( _, let message), .EMPTY_TABLE_NAME( _, let message), .EMPTY_VAULT_ID( _, let message), .EMPTY_VAULT_URL( _, let message), .RECORDS_KEY_ERROR( _, let message),.INVALID_RECORDS_TYPE( _, let message), .EMPTY_COLUMN_NAME( _, let message), .INVALID_BEARER_TOKEN_FORMAT( _, let message), .MISSING_RECORDS_ARRAY( _, let message), .MISSING_RECORDS_IN_ADDITIONAL_FIELDS( _, let message), .EMPTY_RECORDS_OBJECT( _, let message), .MISSING_RECORDS_IN_GETBYID( _, let message),.INVALID_URL( _, let message),.SKYFLOW_IDS_AND_COLUMN_NAME_BOTH_SPECIFIED( _, let message), .MISSING_IDS_OR_COLUMN_VALUES_IN_GET( _, let message), .MISSING_RECORD_COLUMN_VALUE( _, let message), .UPSERT_OPTION_CANNOT_BE_EMPTY( _, let message),.INVALID_COLUMN_VALUES_IN_GET( _, let message),.MISSING_COMPOSABLE_LAYOUT_KEY(_, let message), .MISMATCH_ELEMENT_COUNT_LAYOUT_SUM(_, let message),.EMPTY_TOKEN_ID( _, let message), .ID_KEY_ERROR( _, let message),.REDACTION_WITH_TOKEN_NOT_SUPPORTED( _, let message), .TOKENS_GET_COLUMN_NOT_SUPPPORTED( _, let message),.MISSING_COLUMN_NAME( _, let message),.EMPTY_COMPOSABLE_LAYOUT_ARRAY(_, let message), .INVALID_IDS_TYPE( _, let message),.MISSING_COMPOSABLE_CONTAINER_OPTIONS(code: _, message: let message):
             return message
            // Single value formatting
            // swiftlint:disable:next line_length
        case .UNMOUNTED_COLLECT_ELEMENT( _, let message, let value), .UNMOUNTED_REVEAL_ELEMENT( _, let message, let value), .EMPTY_IDS( _, let message, let value), .EMPTY_ID_VALUE( _, let message, let value),  .TABLE_KEY_ERROR( _, let message, let value), .FIELDS_KEY_ERROR( _, let message, let value), .EMPTY_FIELDS_KEY( _, let message, let value), .REDACTION_KEY_ERROR( _, let message, let value), .MISSING_KEY_IDS( _, let message, let value), .INVALID_TABLE_NAME_TYPE( _, let message, let value), .INVALID_FIELDS_TYPE( _, let message, let value), .INVALID_TOKEN_TYPE( _, let message, let value), .MISSING_TABLE_NAME_IN_USERT_OPTION( _, let message, let value), .MISSING_COLUMN_NAME_IN_USERT_OPTION( _, let message, let value), .COLUMN_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(_, let message, let value), .TABLE_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION( _, let message, let value),  .EMPTY_RECORD_COLUMN_VALUES( _, let message, let value), .EMPTY_COLUMN_VALUE( _, let message, let value), .INVALID_COLUMN_NAME( _, let message, let value), .DUPLICATE_ADDITIONAL_FIELD_FOUND( _, let message, let value), .ERROR_TRIGGERED( _, let message, let value):
            return formatMessage(message, [value])
            // Multi value formatting
        case .DUPLICATE_ELEMENT_FOUND( _, let message, let values):
            return formatMessage(message, values)
        }
    }
    internal var errorObject: NSError {
        NSError(domain: "", code: self.code, userInfo: [NSLocalizedDescriptionKey: self.description])
    }

    internal func getErrorObject(contextOptions: ContextOptions) -> NSError {
        Log.error(message: self.description, contextOptions: contextOptions)
        return SkyflowError(domain: "", code: self.code, userInfo: [NSLocalizedDescriptionKey: "\(self.description)" ])
    }

    internal func formatMessage(_ message: String, _ values: [String]) -> String {
        let words = message.split(separator: " ")
        var valuesIndex = 0
        var result = ""
        for word in words {
            if (word.hasPrefix("<") && word.hasSuffix(">")) || (word.hasPrefix("<") && word.hasSuffix(".")) {
                if(word.contains(".")){
                    result += values[valuesIndex] + "."
                } else {
                    result += values[valuesIndex]
                }
                
                valuesIndex += 1
            } else {
                result += word
            }
            result += " "
        }
        result.removeLast()
        return result
    }
}

public class SkyflowError: NSError {
    var xml: String = ""
    
    func setXML(xml: String) {
        self.xml = xml
    }
    
    public func getXML() -> String {
        return self.xml
    }
}
