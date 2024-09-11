/*
 * Copyright (c) 2022 Skyflow
*/

//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 09/09/21.
//

import Foundation

internal struct ICOptions {
    var tokens: Bool
    var additionalFields: [String: Any]?
    var upsert: [[String: Any]]?
    var callback: Callback?
    var contextOptions: ContextOptions?
    
    init(tokens: Bool = true, additionalFields: [String: Any]? = nil, upsert: [[String:  Any]]? = nil, callback: Callback? = nil, contextOptions: ContextOptions? = nil) {
        self.tokens = tokens
        self.additionalFields = additionalFields
        self.upsert = upsert
        self.callback = callback
        self.contextOptions = contextOptions
    }
    
    public func validateUpsert() ->  Bool{
        if self.upsert != nil {
            if self.upsert!.count == 0 {
                let errorCode = ErrorCodes.UPSERT_OPTION_CANNOT_BE_EMPTY()
                self.callback!.onFailure(errorCode.getErrorObject(contextOptions: self.contextOptions!))
                return true
            }
            
            for (index, currUpsertOption) in (self.upsert ?? [[:]]).enumerated() {
                if currUpsertOption["table"] == nil {
                    let errorCode = ErrorCodes.MISSING_TABLE_NAME_IN_USERT_OPTION(value: "\(index)")
                    self.callback!.onFailure(errorCode.getErrorObject(contextOptions: self.contextOptions!))
                    return true
                }
                if currUpsertOption["column"] == nil {
                    let errorCode = ErrorCodes.MISSING_COLUMN_NAME_IN_USERT_OPTION(value: "\(index)")
                    self.callback!.onFailure(errorCode.getErrorObject(contextOptions: self.contextOptions!))
                    return true
                }
                
                if currUpsertOption["table"] as! String == "" {
                    let errorCode = ErrorCodes.TABLE_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(value: "\(index)")
                    self.callback!.onFailure(errorCode.getErrorObject(contextOptions: self.contextOptions!))
                    return true
                }
                if currUpsertOption["column"] as! String == "" {
                    let errorCode = ErrorCodes.COLUMN_NAME_IS_EMPTY_FOR_ATLEAST_ONE_UPSERT_OPTION(value: "\(index)")
                    self.callback!.onFailure(errorCode.getErrorObject(contextOptions: self.contextOptions!))
                    return true
                }
            }
            
        }
        return false;
    }
}
