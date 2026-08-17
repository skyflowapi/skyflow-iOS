/*
 * Copyright (c) 2022 Skyflow
*/

// Object that describes the Options for Get

import Foundation

public struct GetOptions {
    var tokens: Bool
    public init(tokens: Bool = false) {
        self.tokens = tokens
    }
}
