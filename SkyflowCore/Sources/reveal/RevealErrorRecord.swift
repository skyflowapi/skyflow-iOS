/*
 * Copyright (c) 2022 Skyflow
*/

// Object that signifies error for reveal element

import Foundation

package class RevealErrorRecord {
    package var id: String
    package var error: NSError

    package init(id: String, error: NSError) {
        self.id = id
        self.error = error
    }
}
