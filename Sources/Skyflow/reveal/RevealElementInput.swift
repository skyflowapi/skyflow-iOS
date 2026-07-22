/*
 * Copyright (c) 2022 Skyflow
*/

// Object for reveal element

import Foundation

public struct RevealElementInput {
    internal var token: String
    internal var inputStyles: Styles?
    internal var labelStyles: Styles?
    internal var errorTextStyles: Styles?
    internal var label: String
    internal var altText: String
    internal var redaction: String?
    internal var tokenGroupName: String?

    public init(token: String = "", inputStyles: Styles = Styles(), labelStyles: Styles = Styles(), errorTextStyles: Styles = Styles(), label: String, altText: String = "", redaction: String? = nil, tokenGroupName: String? = nil) {
        self.token = token
        self.inputStyles = inputStyles
        self.labelStyles = labelStyles
        self.errorTextStyles = errorTextStyles
        self.label = label
        self.altText = altText
        self.redaction = redaction
        self.tokenGroupName = tokenGroupName
    }
}
