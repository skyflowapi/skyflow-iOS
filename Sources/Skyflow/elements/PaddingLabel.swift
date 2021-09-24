//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 15/09/21.
//

import Foundation
import UIKit

internal class PaddingLabel: UILabel {
    internal var insets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
//    internal var topInset: CGFloat = 20.0
//    internal var bottomInset: CGFloat = 20.0
//    internal var leftInset: CGFloat = 7.0
//    internal var rightInset: CGFloat = 7.0

    override func drawText(in rect: CGRect) {
//        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
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
