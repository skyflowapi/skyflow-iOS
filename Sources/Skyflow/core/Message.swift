//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 07/10/21.
//

import Foundation

internal enum Message {
    case INITIALIZE_CLIENT
    case CLIENT_INITIALIZED
    case CREATE_COLLECT_CONTAINER
    case COLLECT_CONTAINER_CREATED
    case CREATE_REVEAL_CONTAINER
    case REVEAL_CONTAINER_CREATED
    case VALIDATE_RECORDS
    case VALIDATE_DETOKENIZE_INPUT
    case VALIDATE_GET_BY_ID_INPUT
    case VALIDATE_CONNECTION_CONFIG
    case VALIDATE_COLLECT_RECORDS
    case VALIDATE_REVEAL_RECORDS
    case CREATED_ELEMENT
    case ELEMENT_MOUNTED
    case ELEMENT_REVEALED
    case COLLECT_SUBMIT_SUCCESS
    case REVEAL_SUBMIT_SUCCESS
    case INSERT_DATA_SUCCESS
    case DETOKENIZE_SUCCESS
    case GET_BY_ID_SUCCESS
    case BEARER_TOKEN_RECEIVED
    case INSERT_TRIGGERED
    case DETOKENIZE_TRIGGERED
    case GET_BY_ID_TRIGGERED
    case INVOKE_CONNECTION_TRIGGERED


    // ErrorLogs
    case INVALID_VAULT_ID
    case EMPTY_VAULT_ID
    case INVALID_BEARER_TOKEN
    case INVALID_TABLE_NAME
    case INVALID_CREDENTIALS
    case INVALID_CONTAINER_TYPE
    case INVALID_COLLECT_VALUE
    case RECORDS_KEY_NOT_FOUND
    case EMPTY_RECORDS
    case EMPTY_TABLE_NAME
    case RECORDS_KEY_ERROR
    case TABLE_KEY_ERROR
    case FIELDS_KEY_ERROR
    case INVALID_COLUMN_NAME
    case EMPTY_COLUMN_NAME
    // INVALID_DATA_TYPE:"",
    // VALIDATION_FAILED:"",
    case INVALID_TOKEN_ID
    case EMPTY_TOKEN_ID
    case ID_KEY_ERROR
    case REDACTION_KEY_ERROR
    case INVALID_REDACTION_TYPE
    case EMPTY_TABLE_AND_FIELDS
    case EMPTY_TABLE
    case MISSING_RECORDS
    case INVALID_RECORDS
    case MISSING_TOKEN
    case MISSING_REDACTION
    case MISSING_IDS
    case INVALID_TABLE_OR_COLUMN
    case EMPTY_RECORD_IDS
    case INVALID_RECORD_ID_TYPE
    case MISSING_TABLE
    case INVALID_RECORD_TABLE_VALUE
    case INVALID_RECORD_LABEL
    case INVALID_RECORD_ALT_TEXT
    case MISSING_CONNECTION_URL
    case INVALID_CONNECTION_URL_TYPE
    case INVALID_CONNECTION_URL
    case MISSING_METHODNAME_KEY
    case INVALID_METHODNAME_VALUE
    case INVALID_FIELD
    case INVALID_ELEMENT_TYPE
    case CANNOT_CHANGE_ELEMENT
    case ELEMENT_NOT_MOUNTED
    case ELEMENTS_NOT_MOUNTED
    case CLIENT_CONNECTION
    case COMPLETE_AND_VALID_INPUTS
    case REQUIRED_PARAMS_NOT_PROVIDED
    case UNKNOWN_ERROR
    case TRANSACTION_ERROR
    case CONNECTION_ERROR
    case ERROR_OCCURED
    case MISSING_TOKEN_KEY
    case MISSING_REDACTION_VALUE
    case ELEMENT_MUST_HAVE_TOKEN
    case DUPLICATE_ELEMENT
    
    case VAULT_ID_EMPTY_WARNING
    case VAULT_URL_EMPTY_WARNING


    var description: String {
        switch self {
        case .INITIALIZE_CLIENT: return "Initializing skyflow client" // A
        case .CLIENT_INITIALIZED: return "Initialized skyflow client successfully" // U
        case .CREATE_COLLECT_CONTAINER: return "Creating Collect container" // A
        case .COLLECT_CONTAINER_CREATED: return "Created Collect container successfully" // U
        case .CREATE_REVEAL_CONTAINER: return "Creating Reveal container" // A
        case .REVEAL_CONTAINER_CREATED: return "Created Reveal container successfully" // U
        case .VALIDATE_RECORDS: return "Validating insert records" // U
        case .VALIDATE_DETOKENIZE_INPUT: return "Validating detokenize input" // U
        case .VALIDATE_GET_BY_ID_INPUT: return "Validating getByID input" // U
        case .VALIDATE_CONNECTION_CONFIG: return "Validating connection config" // A
        case .VALIDATE_COLLECT_RECORDS: return "Validating collect element input" // U
        case .VALIDATE_REVEAL_RECORDS: return "Validating reveal element input" // U
        case .CREATED_ELEMENT: return "Created <> element" // U
        case .ELEMENT_MOUNTED: return "<> Element mounted" // A
        case .ELEMENT_REVEALED: return "<> Element revealed" // U?
        case .COLLECT_SUBMIT_SUCCESS: return "Data has been collected successfully." // U
        case .REVEAL_SUBMIT_SUCCESS: return "Data has been revealed successfully." // U
        case .INSERT_DATA_SUCCESS: return "Data has been inserted successfully." // U
        case .DETOKENIZE_SUCCESS: return "Data has been revealed successfully." // U
        case .GET_BY_ID_SUCCESS: return "Data has been revealed successfully." // U
        case .BEARER_TOKEN_RECEIVED: return "GetBearerToken promise received successfully." // U
        case .INSERT_TRIGGERED: return "Insert method triggered."
        case .DETOKENIZE_TRIGGERED: return "Detokenize method triggered."
        case .GET_BY_ID_TRIGGERED: return "Get by ID triggered."
        case .INVOKE_CONNECTION_TRIGGERED: return "Invoke connection triggered."


        // ErrorLogs

        case .INVALID_VAULT_ID: return "Vault Id is invalid or cannot be found." // A
        case .EMPTY_VAULT_ID: return "VaultID is empty."
        case .INVALID_BEARER_TOKEN: return "Bearer token is invalid or expired." // A
        case .INVALID_TABLE_NAME: return "Table Name passed doesn’t exist in the vault with id " // A
        case .INVALID_CREDENTIALS: return "Invalid client credentials" // A
        case .INVALID_CONTAINER_TYPE: return "Invalid container type" // A
        case .INVALID_COLLECT_VALUE: return "Invalid <>"
        case .RECORDS_KEY_NOT_FOUND: return "records object key value not found"
        case .EMPTY_RECORDS: return "records object is empty"
        case .EMPTY_TABLE_NAME: return "Table Name is empty."
        case .RECORDS_KEY_ERROR: return "Key 'records' is missing or payload is incorrectly formatted"
        case .TABLE_KEY_ERROR: return "Key 'table' is missing or payload is incorrectly formatted."
        case .FIELDS_KEY_ERROR: return "Key 'fields' is missing or payload is incorrectly formatted"
        case .INVALID_COLUMN_NAME: return "Column with given name is not present in the table in vault" // A
        case .EMPTY_COLUMN_NAME: return "Column name is empty"
            // INVALID_DATA_TYPE:"",
            // VALIDATION_FAILED:"",
        case .INVALID_TOKEN_ID: return "Token provided is invalid" // A
        case .EMPTY_TOKEN_ID: return "Token is empty"
        case .ID_KEY_ERROR: return "Key 'token' is missing in the payload provided"
        case .REDACTION_KEY_ERROR: return "Key 'redaction' is missing or payload is incorrectly formatted"
        case .INVALID_REDACTION_TYPE: return "Redaction type value isn’t one of: 'PLAIN_TEXT', 'REDACTED' ,'DEFAULT' or 'MASKED'"
        case .EMPTY_TABLE_AND_FIELDS: return
              "table or fields parameter cannot be passed as empty atindex <> in records array"
        case .EMPTY_TABLE: return "Table can't be passed as empty at index <> in records array"
        case .MISSING_RECORDS: return "Missing records property"
        case .INVALID_RECORDS: return "Invalid Records" // ?
        case .MISSING_TOKEN: return "Missing token property"
        case .MISSING_REDACTION: return "Missing Redaction property"
        case .MISSING_IDS: return "Missing ids property"
        case .INVALID_TABLE_OR_COLUMN: return "Invalid table or column" // A
        case .EMPTY_RECORD_IDS: return  "Record ids cannot be Empty"
        case .INVALID_RECORD_ID_TYPE: return "Invalid Type of Records Id"
        case .MISSING_TABLE: return "Missing Table Property"
        case .INVALID_RECORD_TABLE_VALUE: return "Invalid Record Table value"
        case .INVALID_RECORD_LABEL: return "Invalid Record Label Type" // A
        case .INVALID_RECORD_ALT_TEXT: return "Invalid Record altText Type" // A
        case .MISSING_CONNECTION_URL: return "connection URL Key is Missing"
        case .INVALID_CONNECTION_URL_TYPE: return "Invalid connection URL type" // A
        case .INVALID_CONNECTION_URL: return "Invalid connection URL"
        case .MISSING_METHODNAME_KEY: return "methodName Key is Missing"
        case .INVALID_METHODNAME_VALUE: return "Invalid methodName value" // A
        case .INVALID_FIELD: return "Invalid collect element value"
        case .INVALID_ELEMENT_TYPE: return "Provide valid element type" // A
        case .CANNOT_CHANGE_ELEMENT: return "Element can't be changed" // A
        case .ELEMENT_NOT_MOUNTED: return "<> element Not Mounted"
        case .ELEMENTS_NOT_MOUNTED: return "Elements Not Mounted" // ?
        case .CLIENT_CONNECTION: return "client connection not established" // A
        case .COMPLETE_AND_VALID_INPUTS: return "Provide complete and valid inputs"
        case .REQUIRED_PARAMS_NOT_PROVIDED: return "Required params are not provided" // A
        case .UNKNOWN_ERROR: return "Unknown Error"
        case .TRANSACTION_ERROR: return "An error occurred during transaction" // A
        case .CONNECTION_ERROR: return "Error while initializing the connection" // A
        case .ERROR_OCCURED: return "Error occurred" // A
        case .MISSING_TOKEN_KEY: return "token key is Missing"
        case .MISSING_REDACTION_VALUE: return "Missing redaction value"
        case .ELEMENT_MUST_HAVE_TOKEN: return "Element must have token"
        case .DUPLICATE_ELEMENT: return "Duplicate column <> found in <>"
            
        case .VAULT_ID_EMPTY_WARNING: return "Invalid client credentials. VaultID is required."
        case .VAULT_URL_EMPTY_WARNING: return "Invalid client credentials. VaultURL cannot be empty."
        }
    }

    internal func getDescription(values: [String]) -> String {
        return formatMessage(self.description, values)
    }

    internal func formatMessage(_ message: String, _ values: [String]) -> String {
        let words = message.split(separator: " ")
        var valuesIndex = 0
        var result = ""
        for word in words {
            if word.hasPrefix("<") && word.hasSuffix(">") {
                if valuesIndex >= values.count {
                    break
                }
                result += values[valuesIndex]
                valuesIndex += 1
            } else {
                result += word
            }
            result += " "
        }
        if result != "" {
            result.removeLast()
        }
        return result
    }
}
