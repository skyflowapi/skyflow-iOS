/*
 * Copyright (c) 2022 Skyflow
*/

// Object that signifies error for reveal element

import Foundation

class RevealErrorRecord {
    var id: String
    var error: NSError

    init(id: String, error: NSError) {
        self.id = id
        self.error = error
    }
}
