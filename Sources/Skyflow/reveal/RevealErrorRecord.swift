/*
 * Copyright (c) 2022 Skyflow
 */

import Foundation

class RevealErrorRecord {
    var id: String
    var error: NSError

    init(id: String, error: NSError) {
        self.id = id
        self.error = error
    }
}
