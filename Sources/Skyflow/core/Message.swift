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
    case VALIDATE_GATEWAY_CONFIG
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
    case BEARER_TOKEN_LISTENER
    case BEARER_TOKEN_EMITTER
    case BEARER_TOKEN_RESOLVED
    case BEARER_TOKEN_RECEIVED
    case PUREJS_CONTROLLER_INITIALIZED
    case INSERT_CALLED
    case DETOKENIZE_CALLED
    case GET_BY_ID_CALLED
    case INVOKE_GATEWAY_CALLED
    case EMIT_PURE_JS_REQUEST
    case LISTEN_PURE_JS_REQUEST
    case FETCH_RECORDS_RESOLVED
    case FETCH_RECORDS_REJECTED
    case INSERT_RECORDS_RESOLVED
    case INSERT_RECORDS_REJECTED
    case GET_BY_SKYFLOWID_RESOLVED
    case GET_BY_SKYFLOWID_REJECTED
    case SEND_INVOKE_GATEWAY_RESOLVED
    case SEND_INVOKE_GATEWAY_REJECTED
    case FETCH_RECORDS_SUCCESS
    case FETCH_RECORDS_FAILURE
    case INSERT_RECORDS_SUCCESS
    case INSERT_RECORDS_FAILURE
    case GET_BY_SKYFLOWID_SUCCESS
    case GET_BY_SKYFLOWID_FAILURE
    case SEND_INVOKE_GATEWAY_SUCCESS
    case SEND_INVOKE_GATEWAY_FAILURE
    case EMIT_EVENT
    case LISTEN_EVENT
    
    
    //ErrorLogs
    case BEARER_TOKEN_REJECTED
    case INVALID_VAULT_ID
    case EMPTY_VAULT_ID
    case INVALID_BEARER_TOKEN
    case INVALID_TABLE_NAME
    case INVALID_CREDENTIALS
    case INVALID_CONTAINER_TYPE
    case RECORDS_KEY_NOT_FOUND
    case EMPTY_RECORD
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
    case MISSING_GATEWAY_URL
    case INVALID_GATEWAY_URL_TYPE
    case INVALID_GATEWAY_URL
    case MISSING_METHODNAME_KEY
    case INVALID_METHODNAME_VALUE
    case INVALID_IFRAME
    case INVALID_FIELD
    case INVALID_ELEMENT_TYPE
    case CANNOT_CHANGE_ELEMENT
    case ELEMENT_NOT_MOUNTED
    case ELEMENTS_NOT_MOUNTED
    case FRAME_NOT_FOUND
    case CLIENT_CONNECTION
    case COMPLETE_AND_VALID_INPUTS
    case REQUIRED_PARAMS_NOT_PROVIDED
    case INVALID_EVENT_TYPE
    case INVALID_EVENT_LISTENER
    case UNKNOWN_ERROR
    case INVALID_ELEMENT_SELECTOR
    case TRANSACTION_ERROR
    case CONNECTION_ERROR
    case ERROR_OCCURED
    case MISSING_TOKEN_KEY
    case MISSING_REDACTION_VALUE
    case ELEMENT_MUST_HAVE_TOKEN
    case DUPLICATE_ELEMENT
    
    
    var description: String {
        switch self {
        case .INITIALIZE_CLIENT: return "Initializing skyflow client" //A
        case .CLIENT_INITIALIZED: return "Initialized skyflow client successfully" //U
        case .CREATE_COLLECT_CONTAINER: return "Creating Collect container" //A
        case .COLLECT_CONTAINER_CREATED: return "Created Collect container successfully" //U
        case .CREATE_REVEAL_CONTAINER: return "Creating Reveal container" //A
        case .REVEAL_CONTAINER_CREATED: return "Created Reveal container successfully" //U
        case .VALIDATE_RECORDS: return "Validating insert records" //U
        case .VALIDATE_DETOKENIZE_INPUT: return "Validating detokenize input" //U
        case .VALIDATE_GET_BY_ID_INPUT: return "Validating getByID input" //U
        case .VALIDATE_GATEWAY_CONFIG: return "Validating gateway config" //A
        case .VALIDATE_COLLECT_RECORDS: return "Validating collect element input" //U
        case .VALIDATE_REVEAL_RECORDS: return "Validating reveal element input" //U
        case .CREATED_ELEMENT: return "Created <> element" //U
        case .ELEMENT_MOUNTED: return "<> Element mounted" //A
        case .ELEMENT_REVEALED: return "<> Element revealed" //U?
        case .COLLECT_SUBMIT_SUCCESS: return "Data has been collected successfully." //U
        case .REVEAL_SUBMIT_SUCCESS: return "Data has been revealed successfully." //U
        case .INSERT_DATA_SUCCESS: return "Data has been inserted successfully." //U
        case .DETOKENIZE_SUCCESS: return "Data has been revealed successfully." //U
        case .GET_BY_ID_SUCCESS: return "Data has been revealed successfully." //U
        case .BEARER_TOKEN_LISTENER: return "Listening to GetBearerToken event" //A
        case .BEARER_TOKEN_EMITTER: return "Emitted GetBearerToken event" //A
        case .BEARER_TOKEN_RESOLVED: return "GetBearerToken promise resolved  successfully." //A
        case .BEARER_TOKEN_RECEIVED: return "GetBearerToken promise received  successfully." //U
        case .PUREJS_CONTROLLER_INITIALIZED: return "Initialized Skyflow controller successfully" //A
        case .INSERT_CALLED: return "Insert method triggered" //U
        case .DETOKENIZE_CALLED: return "Detokenize method triggered" //U
        case .GET_BY_ID_CALLED: return "GetById method triggered" //U
        case .INVOKE_GATEWAY_CALLED: return "Invoke Gateway method triggered" //U
        case .EMIT_PURE_JS_REQUEST: return "Emitted %s1 request" //A
        case .LISTEN_PURE_JS_REQUEST: return "Listening to %s1  event" //A
        case .FETCH_RECORDS_RESOLVED: return "Detokenize request is resolved" //A
        case .FETCH_RECORDS_REJECTED: return "Detokenize request is rejected" //A
        case .INSERT_RECORDS_RESOLVED: return "Insert request is resolved" //A
        case .INSERT_RECORDS_REJECTED: return "Insert request is rejected" //A
        case .GET_BY_SKYFLOWID_RESOLVED: return "GetById request is resolved" //A
        case .GET_BY_SKYFLOWID_REJECTED: return "GetById request is rejected" //A
        case .SEND_INVOKE_GATEWAY_RESOLVED: return "Invoke gateway request resolved" //A
        case .SEND_INVOKE_GATEWAY_REJECTED: return "Invoke gateway request rejected" //A
        case .FETCH_RECORDS_SUCCESS: return "Detokenize request has succeeded"  //?
        case .FETCH_RECORDS_FAILURE: return "Detokenize request has failed" //?
        case .INSERT_RECORDS_SUCCESS: return "Insert request has succeeded" //?
        case .INSERT_RECORDS_FAILURE: return "Insert request has failed" //?
        case .GET_BY_SKYFLOWID_SUCCESS: return "GetById request has succeeded"
        case .GET_BY_SKYFLOWID_FAILURE: return "GetById request has failed" //?
        case .SEND_INVOKE_GATEWAY_SUCCESS: return "Invoke gateway request has succeeded" //?
        case .SEND_INVOKE_GATEWAY_FAILURE: return "Invoke gateway request has failed" //?
        case .EMIT_EVENT: return "<> event emitted" //A
        case .LISTEN_EVENT: return "Listening to <>" //A
        
        //ErrorLogs
        
        case .BEARER_TOKEN_REJECTED: return "GetBearerToken promise got rejected."
        case .INVALID_VAULT_ID: return "Vault Id is invalid or cannot be found." //A
        case .EMPTY_VAULT_ID: return "VaultID is empty."
        case .INVALID_BEARER_TOKEN: return "Bearer token is invalid or expired." //A
        case .INVALID_TABLE_NAME: return "Table Name passed doesn’t exist in the vault with id " //A
        case .INVALID_CREDENTIALS: return "Invalid client credentials" //A
        case .INVALID_CONTAINER_TYPE: return "Invalid container type" //A
        case .RECORDS_KEY_NOT_FOUND: return "records object key value not found"
        case .EMPTY_RECORD: return "records object is empty"
        case .EMPTY_TABLE_NAME: return "Table Name is empty."
        case .RECORDS_KEY_ERROR: return "Key 'records' is missing or payload is incorrectly formatted"
        case .TABLE_KEY_ERROR: return "Key 'table' is missing or payload is incorrectly formatted."
        case .FIELDS_KEY_ERROR: return "Key 'fields' is missing or payload is incorrectly formatted"
        case .INVALID_COLUMN_NAME: return "Column with given name is not present in the table in vault" //A
        case .EMPTY_COLUMN_NAME: return "Column name is empty"
            // INVALID_DATA_TYPE:"",
            // VALIDATION_FAILED:"",
        case .INVALID_TOKEN_ID: return "Token provided is invalid" //A
        case .EMPTY_TOKEN_ID: return "Token is empty"
        case .ID_KEY_ERROR: return "Key 'token' is missing in the payload provided"
        case .REDACTION_KEY_ERROR: return "Key 'redaction' is missing or payload is incorrectly formatted"
        case .INVALID_REDACTION_TYPE: return "Redaction type value isn’t one of: 'PLAIN_TEXT', 'REDACTED' ,'DEFAULT' or 'MASKED'"
        case .EMPTY_TABLE_AND_FIELDS: return
              "table or fields parameter cannot be passed as empty atindex <> in records array"
        case .EMPTY_TABLE: return "Table can't be passed as empty at index <> in records array"
        case .MISSING_RECORDS: return "Missing records property"
        case .INVALID_RECORDS: return "Invalid Records" //?
        case .MISSING_TOKEN: return "Missing token property"
        case .MISSING_REDACTION: return "Missing Redaction property"
        case .MISSING_IDS: return "Missing ids property"
        case .INVALID_TABLE_OR_COLUMN: return "Invalid table or column" //A
        case .EMPTY_RECORD_IDS: return  "Record ids cannot be Empty"
        case .INVALID_RECORD_ID_TYPE: return "Invalid Type of Records Id"
        case .MISSING_TABLE: return "Missing Table Property"
        case .INVALID_RECORD_TABLE_VALUE: return "Invalid Record Table value"
        case .INVALID_RECORD_LABEL: return "Invalid Record Label Type" //A
        case .INVALID_RECORD_ALT_TEXT: return "Invalid Record altText Type" //A
        case .MISSING_GATEWAY_URL: return "gateway URL Key is Missing"
        case .INVALID_GATEWAY_URL_TYPE: return "Invalid gateway URL type" //A
        case .INVALID_GATEWAY_URL: return "Invalid gateway URL"
        case .MISSING_METHODNAME_KEY: return "methodName Key is Missing"
        case .INVALID_METHODNAME_VALUE: return "Invalid methodName value" //A
        case .INVALID_IFRAME: return "Expecting a valid Iframe" //A
        case .INVALID_FIELD: return "Invalid collect element value"
        case .INVALID_ELEMENT_TYPE: return "Provide valid element type" //A
        case .CANNOT_CHANGE_ELEMENT: return "Element can't be changed" //A
        case .ELEMENT_NOT_MOUNTED: return "<> element Not Mounted"
        case .ELEMENTS_NOT_MOUNTED: return "Elements Not Mounted" //?
        case .FRAME_NOT_FOUND: return "<> frame not found" //A
        case .CLIENT_CONNECTION: return "client connection not established" //A
        case .COMPLETE_AND_VALID_INPUTS: return "Provide complete and valid inputs"
        case .REQUIRED_PARAMS_NOT_PROVIDED: return "Required params are not provided" //A
        case .INVALID_EVENT_TYPE: return "Provide a valid event type" //A
        case .INVALID_EVENT_LISTENER: return "Provide valid event listener" //A
        case .UNKNOWN_ERROR: return "Unknown Error"
        case .INVALID_ELEMENT_SELECTOR: return
              "Provided element selector is not valid or not found" //A
        case .TRANSACTION_ERROR: return "An error occurred during transaction" //A
        case .CONNECTION_ERROR: return "Error while initializing the connection" //A
        case .ERROR_OCCURED: return "Error occurred" //A
        case .MISSING_TOKEN_KEY: return "token key is Missing"
        case .MISSING_REDACTION_VALUE: return "Missing redaction value"
        case .ELEMENT_MUST_HAVE_TOKEN: return "Element must have token"
        case .DUPLICATE_ELEMENT: return "Duplicate column <> found in <>"
        }
    }
    
    internal func getDescription(values: [String]) -> String{
        return formatMessage(self.description, values)
    }
    
    internal func formatMessage(_ message: String, _ values: [String]) -> String {
        let words = message.split(separator: " ")
        var valuesIndex = 0
        var result = ""
        for word in words {
            if word.hasPrefix("<") && word.hasSuffix(">") {
                if(valuesIndex >= values.count) {
                    break;
                }
                result += values[valuesIndex]
                valuesIndex += 1
            }
            else {
                result += word
            }
            result += " "
        }
        if(result != "") {
            result.removeLast()
        }
        return result
    }
}
