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

public struct ICOptions {
    var tokens: Bool
    var additionalFields: [String: Any]?
    
    public init(tokens: Bool = true, additionalFields: [String: Any]? = nil) {
        self.tokens = tokens
        self.additionalFields = additionalFields
    }
}
