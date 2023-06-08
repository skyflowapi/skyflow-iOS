/*
 * Copyright (c) 2022 Skyflow
*/

// List of all error code

import Foundation


internal enum ErrorCodes: CustomStringConvertible {
    // No message values
    case EMPTY_TABLE_NAME(code: Int = 400, message: String = "table key cannot be empty")
    case EMPTY_COLUMN_NAME(code: Int = 400, message: String = "Column Name is empty")
    case EMPTY_VAULT_ID(code: Int = 400, message: String = "Invalid client credentials. VaultID is required.")
    case EMPTY_VAULT_URL(code: Int = 400, message: String = "Invalid client credentials. VaultURL cannot be empty.")
    case EMPTY_CONNECTION_URL(code: Int = 400, message: String = "connectionURL key is empty")
    case EMPTY_REQUEST_XML(code: Int = 400, message: String = "requestXML key is empty")
    case EMPTY_IDS(code: Int = 400, message: String = "ids key cannot be empty")
    case EMPTY_ID_VALUE(code: Int = 400, message: String = "id is empty")
    case RECORDS_KEY_ERROR(code: Int = 400, message: String = "Key 'records' is missing or payload is incorrectly formatted")
    case TABLE_KEY_ERROR(code: Int = 400, message: String = "table key is required")
    case FIELDS_KEY_ERROR(code: Int = 400, message: String = "fields key is required")
    case EMPTY_FIELDS_KEY(code: Int = 400, message: String = "fields key cannot be empty")
    case EMPTY_TOKEN_ID(code: Int = 400, message: String = "Token is empty")
    case ID_KEY_ERROR(code: Int = 400, message: String = "Key 'token' is missing in the payload provided")
    case REDACTION_KEY_ERROR(code: Int = 400, message: String = "redaction key is required")
    case MISSING_KEY_IDS(code: Int = 404, message: String = "ids key is required")
    // New
    case INVALID_TABLE_NAME_TYPE(code: Int = 400, message: String = "Key 'table' is of invalid type")
    case INVALID_FIELDS_TYPE(code: Int = 400, message: String = "Key 'fields' is of invalid type")
    case INVALID_RECORDS_TYPE(code: Int = 400, message: String = "Key 'records' is of invalid type")
    case INVALID_BEARER_TOKEN_FORMAT(code: Int = 400, message: String = "Invalid Bearer token")
    case MISSING_RECORDS_ARRAY(code: Int = 404, message: String = "Missing records array in additional fields")
    case MISSING_RECORDS_IN_ADDITIONAL_FIELDS(code: Int = 404, message: String = "records object key value not found inside additional Fields")
    case EMPTY_RECORDS_OBJECT(code: Int = 404, message: String = "records object cannot be empty")
    case MISSING_RECORDS_IN_GETBYID(code: Int = 404, message: String = "records object cannot be empty")
    case INVALID_TOKEN_TYPE(code: Int = 400, message: String = "Token type must be string")
    case INVALID_URL(code: Int = 400, message: String = "Bad or missing URL")
    case VALIDATIONS_FAILED(code: Int = 400, message: String = "Validations failed")
    case INVALID_PATH_PARAMS(code: Int = 400, message: String = "Invalid path params")
    case INVALID_QUERY_PARAMS(code: Int = 400, message: String = "Invalid query params")
    case INVALID_REQUEST_BODY(code: Int = 400, message: String = "Invalid query params")
    case INVALID_RESPONSE_BODY(code: Int = 400, message: String = "Invalid query params")
    case INVALID_IDS_TYPE(code: Int = 400, message: String = "Invalid type in 'ids'")
    case EMPTY_ELEMENT_ID_REQUEST_XML(code: Int = 400, message: String = "Empty element id present in requestXML")
    case AMBIGUOUS_ELEMENT_FOUND_IN_RESPONSE_XML(code: Int = 400, message: String = "Ambiguous element found in responseXML")
    case DUPLICATE_ELEMENT_FOUND_IN_RESPONSE_XML(code: Int = 400, message: String = "Duplicate element found in responseXML")
    case APIError(code: Int, message: String)

    // Single message value
    case EMPTY_VAULT(code: Int = 400, message: String = "Vault ID <VAULT_ID> is invalid", value: String)
    case INVALID_REDACTION_TYPE(code: Int = 400, message: String = "Redaction type <REDACTION> is invalid", value: String)
    case INVALID_DATA_TYPE_PASSED(code: Int = 400, message: String = "Invalid data type passed to <PARAM_NAME> parameter", value: String)
    case INVALID_VALUE(code: Int = 400, message: String = "Value present in the element with <COLUMN_NAME> is not valid", value: String)
    case DUPLICATE_ELEMENT_IN_RESPONSE_BODY(code: Int = 400, message: String = "Duplicate Skyflow element with label <LABEL> found in response body", value: String)
    case MISSING_KEY_IN_RESPONSE(code: Int = 100, message: String = "Key <KEY> is missing in response", value: String)
    // New
    case UNMOUNTED_COLLECT_ELEMENT(code: Int = 400, message: String = "Element with column name <COLUMN_NAME> is unmounted", value: String)
    case UNMOUNTED_REVEAL_ELEMENT(code: Int = 400, message: String = "Element with token <TOKEN> is unmounted", value: String)
    case UNMOUNTED_ELEMENT_INVOKE_CONNECTION(code: Int = 400, message: String = "element for <FIELD_NAME> is not mounted", value: String)
    case INVALID_ELEMENT_INVOKE_CONNECTION(code: Int = 400, message: String = "element for <FIELD_NAME> is invalid", value: String)
    case ERROR_TRIGGERED(code: Int = 400, message: String = "<TRIGGERED_ERROR_MESSAGE>", value: String)
    case EMPTY_COLUMN_NAME_IN_COLLECT(code: Int = 400, message: String = "element with type <TYPE> - Column key cannot be empty.", value: String)
    case EMPTY_TABLE_NAME_IN_COLLECT(code: Int = 400, message: String = "element with type <TYPE> - Table key cannot be empty.", value: String)
    case EMPTY_TOKEN_INVOKE_CONNECTION(code: Int = 400, message: String = "element for <FIELD_NAME> must have token", value: String)
    case INVALID_ELEMENT_ID_REQUEST_XML(code: Int = 400, message: String = "Invalid element id <ELEMENT_ID> present in requestXML", value: String)
    case INVALID_CONNECTION_URL(code: Int = 400, message: String = "connectionURL <CONNECTION_URL> is invalid", value: String)
    case INVALID_PATH_IN_SOAP_CONNECTION(code: Int = 400, message: String = "Invalid path in responseXML. <ELEMENT_PATH> is not found in response", value: String)
    case INVALID_IDENTIFIERS_IN_SOAP_CONNECTION(code: Int = 400, message: String = "Identifiers for path <ELEMENT_PATH> do not uniquely identify an element in response", value: String)
    case INVALID_REQUEST_XML(code: Int = 400, message: String = "Error parsing Request XML: <AEXML_USER_INFO>", value: String)
    case INVALID_RESPONSE_XML(code: Int = 400, message: String = "Invalid Response XML in SoapConnection: <AEXML_USER_INFO>", value: String)
    case INVALID_ACTUAL_RESPONSE_XML(code: Int = 400, message: String = "Invalid Response returned from server in SoapConnection: <AEXML_USER_INFO>", value: String)
    case REGEX_MATCH_FAILED(code: Int = 400, message: String = "No match found for regex: <REGEX>", value: String)
    // Multiple message values
    case INVALID_TABLE_NAME(code: Int = 400, message: String = "<TABLE_NAME> passed doesn’t exist in the vault with id <VAULT_ID>", values: [String])
    // changed
    case DUPLICATE_ELEMENT_FOUND(code: Int = 400, message: String = "Duplicate element with <TABLE_NAME> and <COLUMN_NAME> found in container", values: [String])
    // new
    case DUPLICATE_ADDITIONAL_FIELD_FOUND(code: Int = 400, message: String = "Duplicate field with <TABLE_NAME> and <COLUMN_NAME> found in additional fields", values: [String])
    case MISSING_TABLE_NAME_IN_USERT_OPTION(code: Int = 400, message: String = "Table name is missing for atleast one of the upsert option")
    case UPSERT_OPTION_CANNOT_BE_EMPTY(code: Int = 400, message: String = "Upsert option must contain atleast one option")
    case MISSING_COLUMN_NAME_IN_USERT_OPTION(code: Int = 400, message: String = "Column name is missing for atleast one of the upsert option")
    case COLUMN_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(code: Int = 400, message: String = "Column name is empty for atleast one of the upsert option")
    case TABLE_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(code: Int = 400, message: String = "Table name is empty for atleast one of the upsert option")
    var code: Int {
        switch self {
        // No Formatting required
        // swiftlint:disable:next line_length
        case .EMPTY_TABLE_NAME(let code, _), .EMPTY_VAULT_ID(let code, _),  .EMPTY_VAULT_URL(let code, _), .EMPTY_CONNECTION_URL(let code, _), .EMPTY_REQUEST_XML(let code, _), .EMPTY_IDS(let code, _), .EMPTY_ID_VALUE(let code, _), .RECORDS_KEY_ERROR( let code, _), .TABLE_KEY_ERROR(let code, _), .FIELDS_KEY_ERROR(let code, _), .EMPTY_FIELDS_KEY(let code, _),.EMPTY_TOKEN_ID(let code, _), .ID_KEY_ERROR(let code, _), .REDACTION_KEY_ERROR(let code, _), .MISSING_KEY_IDS(let code, _), .INVALID_TABLE_NAME_TYPE(let code, _), .INVALID_FIELDS_TYPE(let code, _), .INVALID_RECORDS_TYPE(let code, _), .EMPTY_COLUMN_NAME(let code, _), .INVALID_BEARER_TOKEN_FORMAT(let code, _), .MISSING_RECORDS_ARRAY(let code, _), .MISSING_RECORDS_IN_ADDITIONAL_FIELDS(let code, _), .EMPTY_RECORDS_OBJECT(let code, _), .MISSING_RECORDS_IN_GETBYID(let code, _), .INVALID_TOKEN_TYPE(let code, _), .INVALID_URL(let code, _), .VALIDATIONS_FAILED(let code, _), .INVALID_PATH_PARAMS(let code, _), .INVALID_QUERY_PARAMS(let code, _), .INVALID_REQUEST_BODY(let code, _), .INVALID_RESPONSE_BODY(let code, _), .INVALID_IDS_TYPE(let code, _), .EMPTY_ELEMENT_ID_REQUEST_XML(let code, _), .AMBIGUOUS_ELEMENT_FOUND_IN_RESPONSE_XML(let code, _), .DUPLICATE_ELEMENT_FOUND_IN_RESPONSE_XML(let code, _), .MISSING_TABLE_NAME_IN_USERT_OPTION(let code, _),.MISSING_COLUMN_NAME_IN_USERT_OPTION(let code, _), .UPSERT_OPTION_CANNOT_BE_EMPTY(let code, _), .COLUMN_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(let code,  _), .TABLE_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(let code, _), .APIError(let code, _):
            return code
        // Single value formatting
        // swiftlint:disable:next line_length
        case .EMPTY_VAULT(let code, _, _), .INVALID_REDACTION_TYPE(let code, _, _), .INVALID_DATA_TYPE_PASSED(let code, _, _), .INVALID_VALUE(let code, _, _), .DUPLICATE_ELEMENT_IN_RESPONSE_BODY(let code, _, _), .MISSING_KEY_IN_RESPONSE(let code, _, _), .UNMOUNTED_COLLECT_ELEMENT(let code, _, _), .UNMOUNTED_REVEAL_ELEMENT(let code, _, _), .UNMOUNTED_ELEMENT_INVOKE_CONNECTION(let code, _, _), .INVALID_ELEMENT_INVOKE_CONNECTION(let code, _, _), .ERROR_TRIGGERED(let code, _, _), .EMPTY_COLUMN_NAME_IN_COLLECT(let code, _, _), .EMPTY_TABLE_NAME_IN_COLLECT(let code, _, _), .EMPTY_TOKEN_INVOKE_CONNECTION(let code, _, _), .INVALID_ELEMENT_ID_REQUEST_XML(let code, _, _), .INVALID_CONNECTION_URL(let code, _, _), .INVALID_PATH_IN_SOAP_CONNECTION(let code, _, _), .INVALID_IDENTIFIERS_IN_SOAP_CONNECTION(let code, _, _), .INVALID_REQUEST_XML(let code, _, _), .INVALID_RESPONSE_XML(let code, _, _), .INVALID_ACTUAL_RESPONSE_XML(let code, _, _), .REGEX_MATCH_FAILED(let code, _, _) :
            return code
        // Multi value formatting
        case .INVALID_TABLE_NAME(let code, _, _), .DUPLICATE_ELEMENT_FOUND(let code, _, _), .DUPLICATE_ADDITIONAL_FIELD_FOUND(let code, _, _):
            return code
        }
    }

    internal var description: String {
        switch self {
        // No Formatting required
        // swiftlint:disable:next line_length
        case .EMPTY_TABLE_NAME( _, let message), .EMPTY_VAULT_ID( _, let message), .EMPTY_VAULT_URL( _, let message), .EMPTY_CONNECTION_URL( _, let message), .EMPTY_REQUEST_XML( _, let message), .EMPTY_IDS( _, let message), .EMPTY_ID_VALUE( _, let message), .RECORDS_KEY_ERROR( _, let message), .TABLE_KEY_ERROR(_, let message), .FIELDS_KEY_ERROR(_, let message), .EMPTY_FIELDS_KEY(_, let message),.EMPTY_TOKEN_ID( _, let message), .ID_KEY_ERROR( _, let message), .REDACTION_KEY_ERROR( _, let message), .MISSING_KEY_IDS(_, let message), .INVALID_TABLE_NAME_TYPE( _, let message), .INVALID_FIELDS_TYPE( _, let message), .INVALID_RECORDS_TYPE( _, let message), .EMPTY_COLUMN_NAME( _, let message), .INVALID_BEARER_TOKEN_FORMAT( _, let message), .MISSING_RECORDS_ARRAY( _, let message), .MISSING_RECORDS_IN_ADDITIONAL_FIELDS( _, let message), .EMPTY_RECORDS_OBJECT( _, let message), .MISSING_RECORDS_IN_GETBYID( _, let message), .INVALID_TOKEN_TYPE( _, let message), .INVALID_URL( _, let message), .VALIDATIONS_FAILED( _, let message), .INVALID_PATH_PARAMS( _, let message), .INVALID_QUERY_PARAMS( _, let message), .INVALID_REQUEST_BODY( _, let message), .INVALID_RESPONSE_BODY( _, let message), .INVALID_IDS_TYPE( _, let message), .EMPTY_ELEMENT_ID_REQUEST_XML( _, let message), .AMBIGUOUS_ELEMENT_FOUND_IN_RESPONSE_XML( _, let message), .DUPLICATE_ELEMENT_FOUND_IN_RESPONSE_XML( _, let message), .MISSING_TABLE_NAME_IN_USERT_OPTION( _, let message), .MISSING_COLUMN_NAME_IN_USERT_OPTION( _, let message), .UPSERT_OPTION_CANNOT_BE_EMPTY( _, let message), .COLUMN_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(_,  let message), .TABLE_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(_, let message), .APIError( _, let message):
            return message
        // Single value formatting
        // swiftlint:disable:next line_length
        case .EMPTY_VAULT( _, let message, let value), .INVALID_REDACTION_TYPE( _, let message, let value), .INVALID_DATA_TYPE_PASSED( _, let message, let value), .INVALID_VALUE( _, let message, let value), .DUPLICATE_ELEMENT_IN_RESPONSE_BODY( _, let message, let value), .MISSING_KEY_IN_RESPONSE( _, let message, let value), .UNMOUNTED_COLLECT_ELEMENT( _, let message, let value), .UNMOUNTED_REVEAL_ELEMENT( _, let message, let value), .UNMOUNTED_ELEMENT_INVOKE_CONNECTION( _, let message, let value), .INVALID_ELEMENT_INVOKE_CONNECTION( _, let message, let value), .ERROR_TRIGGERED( _, let message, let value), .EMPTY_COLUMN_NAME_IN_COLLECT( _, let message, let value), .EMPTY_TABLE_NAME_IN_COLLECT( _, let message, let value), .EMPTY_TOKEN_INVOKE_CONNECTION( _, let message, let value), .INVALID_ELEMENT_ID_REQUEST_XML( _, let message, let value), .INVALID_CONNECTION_URL( _, let message, let value), .INVALID_PATH_IN_SOAP_CONNECTION( _, let message, let value), .INVALID_IDENTIFIERS_IN_SOAP_CONNECTION( _, let message, let value), .INVALID_REQUEST_XML( _, let message, let value), .INVALID_ACTUAL_RESPONSE_XML( _, let message, let value), .INVALID_RESPONSE_XML( _, let message, let value), .REGEX_MATCH_FAILED( _, let message, let value):
            return formatMessage(message, [value])
        // Multi value formatting
        case .INVALID_TABLE_NAME( _, let message, let values), .DUPLICATE_ELEMENT_FOUND( _, let message, let values), .DUPLICATE_ADDITIONAL_FIELD_FOUND( _, let message, let values):
            return formatMessage(message, values)
        }
    }
    internal var errorObject: NSError {
        NSError(domain: "", code: self.code, userInfo: [NSLocalizedDescriptionKey: self.description])
    }

    internal func getErrorObject(contextOptions: ContextOptions) -> NSError {
        Log.error(message: self.description, contextOptions: contextOptions)
        return SkyflowError(domain: "", code: self.code, userInfo: [NSLocalizedDescriptionKey: "Interface: \(contextOptions.interface.description) - \(self.description)" ])
    }

    internal func formatMessage(_ message: String, _ values: [String]) -> String {
        let words = message.split(separator: " ")
        var valuesIndex = 0
        var result = ""
        for word in words {
            if word.hasPrefix("<") && word.hasSuffix(">") {
                result += values[valuesIndex]
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
