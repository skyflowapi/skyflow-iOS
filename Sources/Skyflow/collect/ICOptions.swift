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
}
