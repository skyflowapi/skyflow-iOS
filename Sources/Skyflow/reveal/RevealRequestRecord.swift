/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes the reveal record in request body

import Foundation
import SkyflowCore

struct RevealRequestRecord {
    var token: String
    var redaction: String
    init(token: String, redaction: String) {
        self.token = token
        self.redaction = redaction
    }
}
