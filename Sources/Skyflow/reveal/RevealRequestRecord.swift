/*
 * Copyright (c) 2022 Skyflow
 */

import Foundation

// Object that describes the reveal record in request body

struct RevealRequestRecord {
    var token: String
    init(token: String) {
        self.token = token
    }
}
