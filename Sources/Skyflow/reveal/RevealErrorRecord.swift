//
//  File.swift
//  
//
//  Created by Santhosh Kamal Murthy Yennam on 13/08/21.
//

import Foundation

class RevealErrorRecord {
    var id: String
    var error: [String: String]

    init(id: String, error: [String: String]) {
        self.id = id
        self.error = error
    }
}
