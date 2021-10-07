import Foundation


public enum ErrorCodes: CustomStringConvertible {
    
    // No message values
    case EMPTY_TABLE_NAME(code: Int=101, message:String="Table Name is empty")
    case EMPTY_VAULT_ID(code: Int=101, message: String="VaultID is empty")
    case RECORDS_KEY_ERROR(code: Int=101, message: String="Key 'records' is missing or payload is incorrectly formatted")
    case TABLE_KEY_ERROR(code: Int=101, message: String="Key 'table' is missing or payload is incorrectly formatted")
    case FIELDS_KEY_ERROR(code: Int=101, message: String="Key 'fields' is missing or payload is incorrectly formatted")
    case EMPTY_TOKEN_ID(code: Int=101, message: String="Token is empty")
    case ID_KEY_ERROR(code: Int=101, message: String="Key 'id' is missing in the payload provided")
    case REDACTION_KEY_ERROR(code: Int=101, message: String="Redaction type value <PROVIDED_VALUE> isn’t one of: 'PLAIN_TEXT', 'REDACTED', 'DEFAULT' or 'MASKED'")
    case MISSING_KEY_IDS(code: Int=101, message: String="Key 'ids' is not present in the JSON object passed.")

    
    
    // Single message value
    case EMPTY_VAULT(code: Int=100, message: String="Vault ID <VAULT_ID> is invalid", value: String)
    case INVALID_REDACTION_TYPE(code: Int=100, message: String="Vault ID <VAULT_ID> is invalid", value: String)
    case DUPLICATE_ELEMENT_FOUND(code: Int=100, message: String="Duplicate field with <TABLE_NAME> and <COLUMN_NAME> found in additional fields", value: String)
    case INVALID_DATA_TYPE_PASSED(code: Int=100, message: String="Invalid data type passed to <PARAM_NAME> parameter", value: String)
    case INVALID_VALUE(code: Int=100, message: String="Value present in the element with <COLUMN_NAME> is not valid", value: String)
    case DUPLICATE_ELEMENT_IN_RESPONSE_BODY(code: Int=100, message: String="Duplicate Skyflow element with label <LABEL> found in response body", value: String)
    case MISSING_KEY_IN_RESPONSE(code: Int=100, message: String="Key <KEY> is missing in response", value: String)
    

    // Multiple message values
    case INVALID_TABLE_NAME(code: Int=102, message: String="<TABLE_NAME> passed doesn’t exist in the vault with id <VAULT_ID>", values: [String])
    
    var code: Int {
        switch (self) {
        case .EMPTY_VAULT(let code, _, _):
            return code
        default:
            return 0
        }
    }
    
    public var description: String {
        switch (self){
        
        // No Formatting required
        case .EMPTY_TABLE_NAME( _, let message), .EMPTY_VAULT_ID( _, let message), .RECORDS_KEY_ERROR( _, let message), .TABLE_KEY_ERROR(_, let message), .FIELDS_KEY_ERROR(_, let message), .EMPTY_TOKEN_ID( _, let message), .ID_KEY_ERROR( _, let message), .REDACTION_KEY_ERROR( _, let message), .MISSING_KEY_IDS(_, let message):
            return message
        // Single value formatting
        case .EMPTY_VAULT( _, let message, let value), .INVALID_REDACTION_TYPE( _, let message, let value), .DUPLICATE_ELEMENT_FOUND( _, let message, let value), .INVALID_DATA_TYPE_PASSED( _, let message, let value), .INVALID_VALUE( _, let message, let value), .DUPLICATE_ELEMENT_IN_RESPONSE_BODY( _, let message, let value), .MISSING_KEY_IN_RESPONSE( _, let message, let value):
            return formatMessage(message, [value])
        // Multi value formatting
        case .INVALID_TABLE_NAME( _, let message, let values):
            return formatMessage(message, values)

        }
}
    
    internal func formatMessage(_ message: String, _ values: [String]) -> String {
        let words = message.split(separator: " ")
        print(words)
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
