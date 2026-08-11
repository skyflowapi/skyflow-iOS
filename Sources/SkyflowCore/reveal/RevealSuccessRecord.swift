/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes the response of reveal record

import Foundation

package struct RevealSuccessRecord {
    package var token_id: String
    package var value: String
    package init(token_id: String, value: String) {
        self.token_id = token_id
        self.value = value
    }
}
