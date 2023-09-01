/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation

/// Configuration options for a Reveal Element.
public struct RevealElementOptions {
    var format: String?
    var translation: [ Character: String ]?

    /**
    Initializes the Reveal Element options.

    - Parameters:
        - format: Format of the Reveal Element.
        - translation: Custom allowed substitutions and regex patterns for `format`.
    */
    public init(format: String? = nil, translation: [ Character: String ]? = nil) {
        self.format = format
        self.translation = translation
        if (self.translation != nil){
            for (key, value) in self.translation! {
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
