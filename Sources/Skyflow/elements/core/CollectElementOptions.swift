/*
 * Copyright (c) 2022 Skyflow
*/

// An Object that describes Options parameter for SkyflowInputField

import Foundation
#if os(iOS)
import UIKit
#endif

public struct CollectElementOptions {
    var required: Bool
    var enableCardIcon: Bool
    var format: String
    var translation: [ Character: String ]?
    var enableCopy: Bool
    var cardMetaData: [ String: Any]?

    
    public init(required: Bool? = false, enableCardIcon: Bool = true, format: String = "mm/yy", translation: [ Character: String ]? = nil, enableCopy: Bool = false, cardMetaData: [ String: Any]? = nil) {
        self.required = required!
        self.enableCardIcon = enableCardIcon
        self.format = format
        self.translation = translation
        self.enableCopy = enableCopy
        self.cardMetaData = cardMetaData
        
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

