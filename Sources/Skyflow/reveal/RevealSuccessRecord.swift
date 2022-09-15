/*
 * Copyright (c) 2022 Skyflow
 */

//
//  File.swift
//  
//
//  Created by Santhosh Kamal Murthy Yennam on 12/08/21.
//

import Foundation

struct RevealSuccessRecord {
    var token_id: String
    var value: String
    init(token_id: String, value: String) {
        self.token_id = token_id
        self.value = value
    }
}
