/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes the response of reveal record

import Foundation

struct RevealSuccessRecord {
    var token_id: String
    var value: String
    init(token_id: String, value: String) {
        self.token_id = token_id
        self.value = value
    }
}
