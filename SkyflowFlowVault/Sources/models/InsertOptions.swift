/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes the Options for Insert

import Foundation

public struct InsertOptions {
    var upsert: [UpsertOptions]?
    public init(upsert: [UpsertOptions]? = nil) {
        self.upsert = upsert
    }
}
