//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 08/09/21.
//

import Foundation

public struct CollectOptions {
    var tokens: Bool
    var additionalFields: [String: Any]?

    public init(tokens: Bool = true, additionalFields: [String: Any]? = nil) {
        self.tokens = tokens
        self.additionalFields = additionalFields
    }
}
