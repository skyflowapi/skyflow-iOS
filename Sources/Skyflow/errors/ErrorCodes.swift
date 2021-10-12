import Foundation


internal enum ErrorCodes: CustomStringConvertible {
    
    // No message values
    case EMPTY_TABLE_NAME(code: Int=101, message:String="Table Name is empty")
    case EMPTY_COLUMN_NAME(code: Int=101, message:String="Column Name is empty")
    case EMPTY_VAULT_ID(code: Int=101, message: String="VaultID is empty")
    case RECORDS_KEY_ERROR(code: Int=101, message: String="Key 'records' is missing or payload is incorrectly formatted")
    case TABLE_KEY_ERROR(code: Int=101, message: String="Key 'table' is missing or payload is incorrectly formatted")
    case FIELDS_KEY_ERROR(code: Int=101, message: String="Key 'fields' is missing or payload is incorrectly formatted")
    case EMPTY_TOKEN_ID(code: Int=101, message: String="Token is empty")
    case ID_KEY_ERROR(code: Int=101, message: String="Key 'id' is missing in the payload provided")
    case REDACTION_KEY_ERROR(code: Int=101, message: String="Redaction type value <PROVIDED_VALUE> isn’t one of: 'PLAIN_TEXT', 'REDACTED', 'DEFAULT' or 'MASKED'")
    case MISSING_KEY_IDS(code: Int=101, message: String="Key 'ids' is not present in the JSON object passed.")
    // New
    case INVALID_TABLE_NAME_TYPE(code: Int=100, message: String="Key 'table' doesn't have a value of type String")
    case INVALID_FIELDS_TYPE(code: Int=100, message: String="Key 'fields' doesn't have a value of type String")
    case INVALID_RECORDS_TYPE(code: Int=100, message: String="Key 'records' is of invalid type")
    case INVALID_BEARER_TOKEN_FORMAT(code: Int=100, message: String="Invalid Bearer token format")
    case MISSING_RECORDS_ARRAY(code: Int=100, message: String="Missing records array in additional fields")
    case INVALID_TOKEN_TYPE(code: Int=100, message: String="Token type must be string")
    case INVALID_URL(code: Int=100, message: String="Bad or missing URL")
    case VALIDATIONS_FAILED(code: Int=100, message: String="Validations failed")
    case INVALID_PATH_PARAMS(code: Int=100, message: String="Invalid path params")
    case INVALID_QUERY_PARAMS(code: Int=100, message: String="Invalid query params")
    case INVALID_REQUEST_BODY(code: Int=100, message: String="Invalid query params")
    case INVALID_RESPONSE_BODY(code: Int=100, message: String="Invalid query params")
    case INVALID_IDS_TYPE(code: Int=100, message: String="Invalid type in 'ids'")
    
    case APIError(code: Int, message: String)
    
    // Single message value
    case EMPTY_VAULT(code: Int=100, message: String="Vault ID <VAULT_ID> is invalid", value: String)
    case INVALID_REDACTION_TYPE(code: Int=100, message: String="Redacton type <REDACTION> is invalid", value: String)
    case INVALID_DATA_TYPE_PASSED(code: Int=100, message: String="Invalid data type passed to <PARAM_NAME> parameter", value: String)
    case INVALID_VALUE(code: Int=100, message: String="Value present in the element with <COLUMN_NAME> is not valid", value: String)
    case DUPLICATE_ELEMENT_IN_RESPONSE_BODY(code: Int=100, message: String="Duplicate Skyflow element with label <LABEL> found in response body", value: String)
    case MISSING_KEY_IN_RESPONSE(code: Int=100, message: String="Key <KEY> is missing in response", value: String)
    // New
    case UNMOUNTED_COLLECT_ELEMENT(code: Int=100, message: String="Element with column name <COLUMN_NAME> is unmounted", value: String)
    case UNMOUNTED_REVEAL_ELEMENT(code: Int=100, message: String="Element with token <TOKEN> is unmounted", value: String)
    

    // Multiple message values
    case INVALID_TABLE_NAME(code: Int=102, message: String="<TABLE_NAME> passed doesn’t exist in the vault with id <VAULT_ID>", values: [String])
    //changed
    case DUPLICATE_ELEMENT_FOUND(code: Int=100, message: String="Duplicate element with <TABLE_NAME> and <COLUMN_NAME> found in container", values: [String])
    //new
    case DUPLICATE_ADDITIONAL_FIELD_FOUND(code: Int=100, message: String="Duplicate field with <TABLE_NAME> and <COLUMN_NAME> found in additional fields", values: [String])
    
    var code: Int {
        switch (self) {
        // No Formatting required
        case .EMPTY_TABLE_NAME(let code, _), .EMPTY_VAULT_ID(let code, _), .RECORDS_KEY_ERROR( let code, _), .TABLE_KEY_ERROR(let code, _), .FIELDS_KEY_ERROR(let code, _), .EMPTY_TOKEN_ID(let code, _), .ID_KEY_ERROR(let code, _), .REDACTION_KEY_ERROR(let code, _), .MISSING_KEY_IDS(let code, _), .INVALID_TABLE_NAME_TYPE(let code, _), .INVALID_FIELDS_TYPE(let code, _), .INVALID_RECORDS_TYPE(let code, _), .EMPTY_COLUMN_NAME(let code, _), .INVALID_BEARER_TOKEN_FORMAT(let code, _), .MISSING_RECORDS_ARRAY(let code, _), .INVALID_TOKEN_TYPE(let code, _), .INVALID_URL(let code, _) ,.VALIDATIONS_FAILED(let code, _), .INVALID_PATH_PARAMS(let code, _), .INVALID_QUERY_PARAMS(let code, _), .INVALID_REQUEST_BODY(let code, _), .INVALID_RESPONSE_BODY(let code, _),
             .INVALID_IDS_TYPE(let code, _), .APIError(let code, _):
            return code
        // Single value formatting
        case .EMPTY_VAULT(let code, _, _), .INVALID_REDACTION_TYPE(let code, _, _), .INVALID_DATA_TYPE_PASSED(let code, _, _), .INVALID_VALUE(let code, _, _), .DUPLICATE_ELEMENT_IN_RESPONSE_BODY(let code, _, _), .MISSING_KEY_IN_RESPONSE(let code, _, _), .UNMOUNTED_COLLECT_ELEMENT(let code, _, _), .UNMOUNTED_REVEAL_ELEMENT(let code, _, _):
            return code
        // Multi value formatting
        case .INVALID_TABLE_NAME(let code, _, _), .DUPLICATE_ELEMENT_FOUND(let code, _, _), .DUPLICATE_ADDITIONAL_FIELD_FOUND(let code, _, _):
            return code

        }
        
    }
    
    internal var description: String {
        switch (self){
        
        // No Formatting required
        case .EMPTY_TABLE_NAME( _, let message), .EMPTY_VAULT_ID( _, let message), .RECORDS_KEY_ERROR( _, let message), .TABLE_KEY_ERROR(_, let message), .FIELDS_KEY_ERROR(_, let message), .EMPTY_TOKEN_ID( _, let message), .ID_KEY_ERROR( _, let message), .REDACTION_KEY_ERROR( _, let message), .MISSING_KEY_IDS(_, let message), .INVALID_TABLE_NAME_TYPE( _, let message), .INVALID_FIELDS_TYPE( _, let message), .INVALID_RECORDS_TYPE( _, let message), .EMPTY_COLUMN_NAME( _, let message), .INVALID_BEARER_TOKEN_FORMAT( _, let message), .MISSING_RECORDS_ARRAY( _, let message), .INVALID_TOKEN_TYPE( _, let message), .INVALID_URL( _, let message) ,.VALIDATIONS_FAILED( _, let message), .INVALID_PATH_PARAMS( _, let message), .INVALID_QUERY_PARAMS( _, let message), .INVALID_REQUEST_BODY( _, let message), .INVALID_RESPONSE_BODY( _, let message),
             .INVALID_IDS_TYPE( _, let message), .APIError( _, let message):
            return message
        // Single value formatting
        case .EMPTY_VAULT( _, let message, let value), .INVALID_REDACTION_TYPE( _, let message, let value), .INVALID_DATA_TYPE_PASSED( _, let message, let value), .INVALID_VALUE( _, let message, let value), .DUPLICATE_ELEMENT_IN_RESPONSE_BODY( _, let message, let value), .MISSING_KEY_IN_RESPONSE( _, let message, let value), .UNMOUNTED_COLLECT_ELEMENT( _, let message, let value), .UNMOUNTED_REVEAL_ELEMENT( _, let message, let value):
            print("SINGLE VALUE FORMATTING")
            return formatMessage(message, [value])
        // Multi value formatting
        case .INVALID_TABLE_NAME( _, let message, let values), .DUPLICATE_ELEMENT_FOUND( _, let message, let values), .DUPLICATE_ADDITIONAL_FIELD_FOUND( _, let message, let values):
            print("MULTIPLE VALUE FORMATTING")
            return formatMessage(message, values)

        }
    }
    internal var errorObject: NSError {
        NSError(domain: "", code: self.code, userInfo: [NSLocalizedDescriptionKey: self.description])
    }
    
    internal func getErrorObject(contextOptions: ContextOptions) -> NSError {
        Log.error(message: self.description, contextOptions: contextOptions)
        return errorObject
    }
    
    internal func formatMessage(_ message: String, _ values: [String]) -> String {
        let words = message.split(separator: " ")
        var valuesIndex = 0
        var result = ""
        for word in words {
            if word.hasPrefix("<") && word.hasSuffix(">") {
                result += values[valuesIndex]
                valuesIndex += 1
            }
            else {
                result += word
            }
            result += " "
        }
        result.removeLast()
        return result
    }
    
    
}
