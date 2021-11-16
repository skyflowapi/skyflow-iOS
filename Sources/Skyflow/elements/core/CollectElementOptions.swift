import Foundation
#if os(iOS)
import UIKit
#endif

public struct CollectElementOptions {
    var required: Bool
    var enableCardIcon: Bool
    public init(required: Bool? = false, enableCardIcon: Bool = true) {
        self.required = required!
        self.enableCardIcon = enableCardIcon
    }
}
