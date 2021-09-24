//
//  File.swift
//  
//
//  Created by Santhosh Kamal Murthy Yennam on 12/08/21.
//

import Foundation

struct RevealRequestRecord {
    var token: String
    var redaction: String
    init(token: String, redaction: String) {
        self.token = token
        self.redaction = redaction
    }
}
