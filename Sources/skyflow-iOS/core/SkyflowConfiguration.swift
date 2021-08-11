//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 03/08/21.
//

import Foundation

public struct SkyflowConfiguration {
    var vaultId: String
    var vaultURL: String
    var tokenProvider: TokenProvider
    var options: SkyflowOptions?
    
    public init(vaultId: String, vaultURL: String, tokenProvider: TokenProvider, options: SkyflowOptions? = SkyflowOptions()) {
        self.vaultId = vaultId
        self.vaultURL = vaultURL
        self.tokenProvider = tokenProvider
        self.options = options
    }
}
