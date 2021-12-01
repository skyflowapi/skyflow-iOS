import Foundation
#if os(iOS)
import UIKit
#endif

public struct CollectElementOptions {
    var required: Bool
    var enableCardIcon: Bool
    var expiryDateFormat: String
    public init(required: Bool? = false, enableCardIcon: Bool = true, expiryDateFormat: String = "mm/yyyy") {
        self.required = required!
        self.enableCardIcon = enableCardIcon
        self.expiryDateFormat = expiryDateFormat
    }
}

