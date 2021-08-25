//
//  File.swift
//  
//
//  Created by Santhosh Kamal Murthy Yennam on 12/08/21.
//

import Foundation

struct RevealSuccessRecord {
    var token_id : String
    var fields : [String:String]
    init(token_id:String,fields:[String:String]) {
        self.token_id = token_id
        self.fields = fields
    }
}
