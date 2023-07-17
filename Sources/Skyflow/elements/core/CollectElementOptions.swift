/*
 * Copyright (c) 2022 Skyflow
*/

// An Object that describes Options parameter for SkyflowInputField

import Foundation
#if os(iOS)
import UIKit
#endif

/// This is the description for CollectElementOptions struct.
public struct CollectElementOptions {
    var required: Bool
    var enableCardIcon: Bool
    var format: String
    var translation: [ Character: String ]?

    /**
    This is the description for init method.

    - Parameters:
        - required: This is the description for required parameter.
        - enableCardIcon: This is the description for enableCardIcon parameter.
        - format: This is the description for format parameter.
        - translation: This is the description for translation parameter.
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

