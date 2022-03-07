import Foundation


struct TestData : Codable {
    var CLIENT: ClientData
    var VAULT: VaultData
    var CONNECTION: ConnectionData
}

struct ClientData: Codable {
    var INVALID_VAULT_ID : String
    var INVALID_VAULT_URL: String
    var VAULT_ID: String
    var VAULT_URL: String
}

struct VaultData: Codable {
    var TABLE_NAME: String;
    var INVALID_TABLE_NAME: String
    var VALID_FIELDS: [Field]
    var INVALID_FIELD: Field
    
    var VALID_TOKENS: [String]
    var INVALID_TOKEN: String
    
    var VALID_IDS: [String]
    var INVALID_ID: String
}

struct ConnectionData: Codable {
    var INVALID_URL: String
    var VALID_URL: String
    
    var PARAMS: Params
    var REQUEST_BODY: ConnectionField
    var INVALID_REQUEST_BODY: ConnectionField
    var RESPONSE_BODY: ConnectionField
    var INVALID_RESPONSE_BODY: ConnectionField
}

struct Params: Codable {
    var PATH_PARAM: Field
    var QUERY_PARAM: Field
    var INVALID_PARAM: Field
}


struct Field: Codable {
    var NAME: String
    var VALUE: String
}

struct ConnectionField: Codable {
    var JSON: [String: String]
    var XML: String
}




