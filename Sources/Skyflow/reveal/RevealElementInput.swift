//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 11/08/21.
//

import Foundation

public struct RevealElementInput {
    internal var token: String
    internal var inputStyles: Styles?
    internal var labelStyles: Styles?
    internal var errorTextStyles: Styles?
    internal var label: String
    internal var redaction: RedactionType
    internal var altText: String?

    public init(token: String = "", inputStyles: Styles? = Styles(), labelStyles: Styles? = Styles(), errorTextStyles: Styles? = Styles(), label: String, redaction: RedactionType, altText: String? = nil) {
        self.token = token
        self.inputStyles = inputStyles
        self.labelStyles = labelStyles
        self.errorTextStyles = errorTextStyles
        self.label = label
        self.redaction = redaction
        self.altText = altText
    }
}
