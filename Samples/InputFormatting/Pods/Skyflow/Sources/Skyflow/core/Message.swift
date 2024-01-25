/*
 * Copyright (c) 2022 Skyflow
*/

//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 07/10/21.
//

import Foundation

internal enum Message {
    case CLIENT_INITIALIZED
    case COLLECT_CONTAINER_CREATED
    case REVEAL_CONTAINER_CREATED
    case VALIDATE_RECORDS
    case VALIDATE_DETOKENIZE_INPUT
    case VALIDATE_GET_BY_ID_INPUT
    case VALIDATE_GET_INPUT
    case VALIDATE_COLLECT_RECORDS
    case VALIDATE_REVEAL_RECORDS
    case CREATED_ELEMENT
    case ELEMENT_REVEALED
    case COLLECT_SUBMIT_SUCCESS
    case REVEAL_SUBMIT_SUCCESS
    case INSERT_DATA_SUCCESS
    case DETOKENIZE_SUCCESS
    case GET_BY_ID_SUCCESS
    case GET_SUCCESS
    case BEARER_TOKEN_RECEIVED
    case INSERT_TRIGGERED
    case DETOKENIZE_TRIGGERED
    case GET_BY_ID_TRIGGERED
    case GET_TRIGGERED

    //Used in tests
    case CLIENT_CONNECTION
    case CANNOT_CHANGE_ELEMENT

    
    //Warnings
    case INVALID_EXPIRYDATE_FORMAT
    case VAULT_ID_EMPTY_WARNING
    case VAULT_URL_EMPTY_WARNING
    case SET_VALUE_WARNING
    case CLEAR_VALUE_WARNING
    case NO_REGEX_MATCH_FOUND
    case FORMAT_AND_TRANSLATION
    case EMPTY_TRANSLATION_VALUE
    case VALIDATE_COMPOSABLE_RECORDS


    var description: String {
        switch self {
        case .CLIENT_INITIALIZED: return "Initialized skyflow client successfully" // U
        case .COLLECT_CONTAINER_CREATED: return "Created Collect container successfully" // U
        case .REVEAL_CONTAINER_CREATED: return "Created Reveal container successfully" // U
        case .VALIDATE_RECORDS: return "Validating insert records" // U
        case .VALIDATE_DETOKENIZE_INPUT: return "Validating detokenize input" // U
        case .VALIDATE_GET_BY_ID_INPUT: return "Validating getByID input" // U
        case .VALIDATE_COLLECT_RECORDS: return "Validating collect element input" // U
        case .VALIDATE_COMPOSABLE_RECORDS: return "Validating composable element input" // U

        case .VALIDATE_REVEAL_RECORDS: return "Validating reveal element input" // U
        case .CREATED_ELEMENT: return "Created <> element" // U
        case .ELEMENT_REVEALED: return "<> Element revealed" // U?
        case .COLLECT_SUBMIT_SUCCESS: return "Data has been collected successfully." // U
        case .REVEAL_SUBMIT_SUCCESS: return "Data has been revealed successfully." // U
        case .INSERT_DATA_SUCCESS: return "Data has been inserted successfully." // U
        case .DETOKENIZE_SUCCESS: return "Data has been revealed successfully." // U
        case .GET_BY_ID_SUCCESS: return "Data has been revealed successfully." // U
        case .GET_SUCCESS: return "Data has been revealed successfully." // U
        case .BEARER_TOKEN_RECEIVED: return "GetBearerToken promise received successfully." // U
        case .INSERT_TRIGGERED: return "Insert method triggered."
        case .DETOKENIZE_TRIGGERED: return "Detokenize method triggered."
        case .GET_BY_ID_TRIGGERED: return "Get by ID triggered."
            
        //Used in tests
        case .CLIENT_CONNECTION: return "client connection not established" // A
        case .CANNOT_CHANGE_ELEMENT: return "Element can't be changed" // A

            
        //Warnings
        case .INVALID_EXPIRYDATE_FORMAT: return "<FORMAT> is not a valid date format"
        case .VAULT_ID_EMPTY_WARNING: return "Invalid client credentials. VaultID is required."
        case .VAULT_URL_EMPTY_WARNING: return "Invalid client credentials. VaultURL cannot be empty."
        case .SET_VALUE_WARNING: return "<ELEMENT_TYPE> setValue() cannot be invoked while in PROD env. It is Not Recommended."
        case .CLEAR_VALUE_WARNING: return "<ELEMENT_TYPE> clearValue() cannot be invoked while in PROD env. It is Not Recommended."
        case .NO_REGEX_MATCH_FOUND: return "No match found for regex - <REGEX>"
        case .GET_TRIGGERED: return "Get Method triggered."
        case .VALIDATE_GET_INPUT: return "Validating getByID input."
        case .FORMAT_AND_TRANSLATION: return "format or translation are not supported on <ELEMENT_TYPE> element type"
        case .EMPTY_TRANSLATION_VALUE: return "Value is empty in Translation Key"
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
