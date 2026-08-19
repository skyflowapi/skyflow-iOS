/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes the option of Collect

import Foundation

public struct CollectOptions {
    var additionalFields: AdditionalFields?
    var upsert: [UpsertOptions]?
    public init(additionalFields: AdditionalFields? = nil, upsert: [UpsertOptions]? = nil) {
        self.additionalFields = additionalFields
        self.upsert = upsert
    }
}
