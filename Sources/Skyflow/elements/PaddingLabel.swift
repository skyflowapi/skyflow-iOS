/*
 * Copyright (c) 2022 Skyflow
*/

// Impletementation for TextField other than SkyflowInputField, for ex : [validation error, label, reveal element]


import Foundation
import UIKit

internal class PaddingLabel: UILabel {
    internal var insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right,
                      height: size.height + insets.top + insets.bottom)
    }

    override var bounds: CGRect {
        didSet {
            // ensures this works within stack views if multi-line
            preferredMaxLayoutWidth = bounds.width - (insets.left + insets.right)
        }
    }
}
