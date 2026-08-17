/*
 * Copyright (c) 2022 Skyflow
*/

// Shared storage for the reveal element options. Each SDK product defines its
// own public `BaseRevealElementOptions` struct exposing that contract's
// initializer (identical in both contracts today).

import Foundation

package struct BaseRevealElementOptions {
    package var format: String?
    package var translation: [ Character: String ]?
    package var enableCopy: Bool?

    package init(format: String? = nil, translation: [ Character: String ]? = nil, enableCopy: Bool? = false) {
        self.format = format
        self.translation = translation
        self.enableCopy = enableCopy
        if (self.translation != nil){
            for (_, value) in self.translation! {
                if value == "" {
                    var contextOptions =  ContextOptions()
                    contextOptions.interface = .REVEAL_CONTAINER
                    contextOptions.logLevel = .WARN
                    Log.warn(message: .EMPTY_TRANSLATION_VALUE, values: [], contextOptions: contextOptions)
                }
            }

        }
    }

}
