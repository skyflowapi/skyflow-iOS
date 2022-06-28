/*
 * Copyright (c) 2022 Skyflow
*/

//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 03/08/21.
//

import Foundation

public struct Configuration {
    var vaultID: String
    var vaultURL: String
    var tokenProvider: TokenProvider
    var options: Options?

    public init(vaultID: String = "", vaultURL: String = "", tokenProvider: TokenProvider, options: Options? = Options()) {
        self.vaultID = vaultID
        self.vaultURL = vaultURL
        self.tokenProvider = tokenProvider
        self.options = options
    }
}
