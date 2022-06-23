/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation
#if os(iOS)
import UIKit
#endif

public struct CollectElementOptions {
    var required: Bool
    var enableCardIcon: Bool
    var format: String
    
    
    public init(required: Bool? = false, enableCardIcon: Bool = true, format: String = "mm/yy") {
        self.required = required!
        self.enableCardIcon = enableCardIcon
        
        self.format = format.lowercased()
    }
}

