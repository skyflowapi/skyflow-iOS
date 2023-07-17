/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation

/// This is the description for RevealElementOptions struct
public struct RevealElementOptions {
    var format: String?
    var translation: [ Character: String ]?

    /**
    This is the description for init method.

    - Parameters:
        - format: This is the description for format parameter.
        - translation: This is the description for translation parameter.
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
