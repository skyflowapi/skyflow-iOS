//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 09/09/21.
//

import Foundation

public struct ICOptions {
    var tokens : Bool
    var extraData: [String: Any]?
    
    public init(tokens: Bool = true, extraData: [String: Any]? = nil){
        self.tokens = tokens
        self.extraData = extraData
    }
}
