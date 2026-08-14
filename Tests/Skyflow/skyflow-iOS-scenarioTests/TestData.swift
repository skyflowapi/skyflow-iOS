/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation


struct TestData : Codable {
    var CLIENT: ClientData
    var VAULT: VaultData
    var CONNECTION: ConnectionData

    // Used when the TEST_DATA env var (normally supplied via CI secrets) isn't set, so running
    // these scenario tests locally fails at the network layer instead of crashing at setUp.
    static let dummyJSON = """
    {
        "CLIENT": {
            "INVALID_VAULT_ID": "invalid_vault_id",
            "INVALID_VAULT_URL": "https://invalid.vault.skyflowapis.dev/",
            "VAULT_ID": "dummy_vault_id",
            "VAULT_URL": "https://dummy.vault.skyflowapis.dev/"
        },
        "VAULT": {
            "TABLE_NAME": "persons",
            "INVALID_TABLE_NAME": "invalid_table",
            "VALID_FIELDS": [{"NAME": "name", "VALUE": "john"}],
            "INVALID_FIELD": {"NAME": "invalid_field", "VALUE": "value"},
            "VALID_TOKENS": ["dummy_token_1"],
            "INVALID_TOKEN": "invalid_token",
            "VALID_IDS": ["dummy_id_1"],
            "INVALID_ID": "invalid_id"
        },
        "CONNECTION": {
            "INVALID_URL": "https://invalid.connection.dummy/",
            "VALID_URL": "https://dummy.connection.dummy/",
            "PARAMS": {
                "PATH_PARAM": {"NAME": "path", "VALUE": "value"},
                "QUERY_PARAM": {"NAME": "query", "VALUE": "value"},
                "INVALID_PARAM": {"NAME": "invalid", "VALUE": "value"}
            },
            "REQUEST_BODY": {"JSON": {}, "XML": "<xml></xml>"},
            "INVALID_REQUEST_BODY": {"JSON": {}, "XML": "<xml></xml>"},
            "RESPONSE_BODY": {"JSON": {}, "XML": "<xml></xml>"},
            "INVALID_RESPONSE_BODY": {"JSON": {}, "XML": "<xml></xml>"}
        }
    }
    """
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




