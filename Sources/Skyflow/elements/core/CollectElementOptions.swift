/*
 * Copyright (c) 2022 Skyflow
*/

// An Object that describes Options parameter for SkyflowInputField

import Foundation
#if os(iOS)
import UIKit
#endif

/// Contains the additional options for Collect Element.
public struct CollectElementOptions {
    var required: Bool
    var enableCardIcon: Bool
    var format: String
    var translation: [ Character: String ]?

    /**
    Initializes the Collect element options.

    - Parameters:
        - required: Indicates whether the field is marked as required. Defaults to `false`.
        - enableCardIcon: Indicates whether card icon should be enabled (only for CARD_NUMBER inputs).
        - format: Format of the Collect Element.
        - translation: Allowed data type values for format.
    */
    public init(required: Bool? = false, enableCardIcon: Bool = true, format: String = "mm/yy", translation: [ Character: String ]? = nil) {
        self.required = required!
        self.enableCardIcon = enableCardIcon
        self.format = format
        self.translation = translation
        
        if (self.translation != nil){
            for (key, value) in self.translation! {
                if value == "" {
                    var contextOptions =  ContextOptions()
                    contextOptions.interface = InterfaceName.COLLECT_CONTAINER
                    contextOptions.logLevel = .WARN
                    Log.warn(message: .EMPTY_TRANSLATION_VALUE, values: [], contextOptions: contextOptions)
                }
            }

        }
    }

}

