/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes the option of Collect

import Foundation

public struct CollectOptions {
    var additionalFields: [String: Any]?
    var upsert: [UpsertOption]?
    public init(additionalFields: [String: Any]? = nil, upsert: [UpsertOption]? = nil) {
        self.additionalFields = additionalFields
        self.upsert = upsert
    }
}
