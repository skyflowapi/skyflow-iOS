//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 03/08/21.
//

import Foundation
import UIKit

public struct SkyflowStyles{
    var base: SkyflowStyle?
    var completed: SkyflowStyle?
    var empty: SkyflowStyle?
    var focus: SkyflowStyle?
    var invalid: SkyflowStyle?
    
    public init(base: SkyflowStyle?, completed: SkyflowStyle?, empty: SkyflowStyle?, focus: SkyflowStyle?, invalid: SkyflowStyle?) {
        self.base = base
        self.completed = completed
        self.empty = empty
        self.focus = focus
        self.invalid = invalid
    }
}

public struct SkyflowStyle{
    var borderColor: UIColor?
    var cornerRadius: CGFloat?
    var padding: CGFloat?
    var borderWidth: CGFloat?
    var font: UIFont?
    var textAlignment: NSTextAlignment?
    var textColor: UIColor?
    
    public init(borderColor: UIColor?, cornerRadius: CGFloat?, padding: CGFloat?, borderWidth: CGFloat?, font:  UIFont?, textAlignment: NSTextAlignment?, textColor: UIColor?) {
        self.borderColor = borderColor
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.borderWidth = borderWidth
        self.font = font
        self.textAlignment = textAlignment
        self.textColor = textColor
    }
}

