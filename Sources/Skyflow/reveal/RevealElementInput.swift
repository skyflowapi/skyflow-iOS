/*
 * Copyright (c) 2022 Skyflow
*/

// Object for reveal element

import Foundation

/// This is the description for RevealElementInpt struct.
public struct RevealElementInput {
    internal var token: String
    internal var inputStyles: Styles?
    internal var labelStyles: Styles?
    internal var errorTextStyles: Styles?
    internal var label: String
    internal var redaction: RedactionType
    internal var altText: String

    public init(token: String = "", inputStyles: Styles = Styles(), labelStyles: Styles = Styles(), errorTextStyles: Styles = Styles(), label: String, redaction: RedactionType = .PLAIN_TEXT, altText: String = "") {
        self.token = token
        self.inputStyles = inputStyles
        self.labelStyles = labelStyles
        self.errorTextStyles = errorTextStyles
        self.label = label
        self.redaction = redaction
        self.altText = altText
    }

    /**
    This is the description for init method.

    - Parameters:
        - token: This is the description for token parameter.
        - inputStyles: This is the description for inputStyles parameter.
        - labelStyles: This is the description for labelStyles parameter.
        - errorTextStyles: This is the description for errorTextStyles parameter.
        - label: This is the description for label parameter.
        - altText: This is the description for altText parameter.
    */
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
