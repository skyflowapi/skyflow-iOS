/*
 * Copyright (c) 2022 Skyflow
*/

// Object for reveal element

import Foundation

public struct RevealElementInput {
    public var token: String
    public var inputStyles: Styles?
    public var labelStyles: Styles?
    public var errorTextStyles: Styles?
    public var label: String
    public var redaction: RedactionType
    public var altText: String

    public init(token: String = "", inputStyles: Styles = Styles(), labelStyles: Styles = Styles(), errorTextStyles: Styles = Styles(), label: String, redaction: RedactionType = .PLAIN_TEXT, altText: String = "") {
        self.token = token
        self.inputStyles = inputStyles
        self.labelStyles = labelStyles
        self.errorTextStyles = errorTextStyles
        self.label = label
        self.redaction = redaction
        self.altText = altText
    }

    public init(token: String = "", inputStyles: Styles = Styles(), labelStyles: Styles = Styles(), errorTextStyles: Styles = Styles(), label: String, altText: String = "") {
        self.token = token
        self.inputStyles = inputStyles
        self.labelStyles = labelStyles
        self.errorTextStyles = errorTextStyles
        self.label = label
        self.redaction = .PLAIN_TEXT
        self.altText = altText
    }
}
