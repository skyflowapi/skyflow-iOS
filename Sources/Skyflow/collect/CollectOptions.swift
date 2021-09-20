//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 08/09/21.
//

import Foundation

public struct CollectOptions {
    var tokens : Bool
    var extraData: [String: Any]?
    
    public init(tokens: Bool = true, extraData: [String: Any]? = nil){
        self.tokens = tokens
        self.extraData = extraData
    }
}
