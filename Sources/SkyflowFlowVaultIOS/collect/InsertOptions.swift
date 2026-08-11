/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes the Options for Insert

import Foundation

public struct InsertOptions {
    var upsert: [UpsertOption]?
    public init(upsert: [UpsertOption]? = nil) {
        self.upsert = upsert
    }
}
