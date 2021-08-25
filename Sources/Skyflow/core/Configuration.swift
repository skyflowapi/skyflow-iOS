//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 03/08/21.
//

import Foundation

public struct Configuration {
    var vaultId: String
    var vaultURL: String
    var tokenProvider: TokenProvider
    var options: Options?
    
    public init(vaultId: String, vaultURL: String, tokenProvider: TokenProvider, options: Options? = Options()) {
        self.vaultId = vaultId
        self.vaultURL = vaultURL
        self.tokenProvider = tokenProvider
        self.options = options
    }
}
