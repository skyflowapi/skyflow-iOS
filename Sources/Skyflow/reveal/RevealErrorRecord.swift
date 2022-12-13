/*
 * Copyright (c) 2022 Skyflow
 */

import Foundation

// Object that signifies error for reveal element

class RevealErrorRecord {
    var id: String
    var error: NSError

    init(id: String, error: NSError) {
        self.id = id
        self.error = error
    }
}
