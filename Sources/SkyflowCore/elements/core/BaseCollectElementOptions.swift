/*
 * Copyright (c) 2022 Skyflow
*/

// Shared storage for the collect element options. Each SDK product defines its
// own public `CollectElementOptions` struct exposing that contract's
// initializer (identical in both contracts today); those structs wrap this
// value and hand it to the core element factories.

import Foundation
#if os(iOS)
import UIKit
#endif

package struct BaseCollectElementOptions {
    package var required: Bool
    package var enableCardIcon: Bool
    package var format: String
    package var translation: [ Character: String ]?
    package var enableCopy: Bool
    package var cardMetaData: [ String: Any]?

    package init(required: Bool = false, enableCardIcon: Bool = true, format: String = "mm/yy", translation: [ Character: String ]? = nil, enableCopy: Bool = false, cardMetaData: [ String: Any]? = nil) {
        self.required = required
        self.enableCardIcon = enableCardIcon
        self.format = format
        self.translation = translation
        self.enableCopy = enableCopy
        self.cardMetaData = cardMetaData

        if (self.translation != nil){
            for (_, value) in self.translation! {
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
