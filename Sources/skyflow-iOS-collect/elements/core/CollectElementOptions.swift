
import Foundation
#if os(iOS)
import UIKit
#endif

public struct CollectElementOptions {
 
    var required : Bool
    public init(required: Bool? = false){
        self.required = required!
    }
}

