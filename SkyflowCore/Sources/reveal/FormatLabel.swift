/*
 * Copyright (c) 2022 Skyflow
*/

// class for RevealElement TextField

import Foundation
import UIKit

public class FormatLabel: UILabel {
    internal var secureText: String? {
        set {
            super.text = newValue
        }
        get {
            return super.text
        }
    }
}
