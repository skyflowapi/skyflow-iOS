/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes the reveal record in request body

import Foundation

struct RevealRequestRecord {
    var token: String
    init(token: String) {
        self.token = token
    }
}
