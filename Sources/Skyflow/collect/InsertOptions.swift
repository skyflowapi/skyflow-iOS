/*
 * Copyright (c) 2022 Skyflow
*/

//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 28/07/21.
//

import Foundation

public struct InsertOptions {
    var tokens: Bool
    var upsert: [[String: Any]]?
    public init(tokens: Bool = true, upsert: [[String:  Any]]? = nil) {
        self.tokens = tokens
        self.upsert = upsert
    }
}
