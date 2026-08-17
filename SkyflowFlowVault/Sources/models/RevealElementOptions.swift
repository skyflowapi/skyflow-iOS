/*
 * Copyright (c) 2022 Skyflow
*/

// Options for reveal elements. Contract-identical in both SDKs today;
// declared per SDK so either product can evolve independently.

import Foundation

public struct RevealElementOptions {
    package var data: BaseRevealElementOptions

    public init(format: String? = nil, translation: [ Character: String ]? = nil, enableCopy: Bool? = false) {
        self.data = BaseRevealElementOptions(format: format, translation: translation, enableCopy: enableCopy)
    }
}
