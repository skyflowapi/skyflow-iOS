/*
 * Copyright (c) 2022 Skyflow
*/

// Object for reveal element

import Foundation

/// Configuration for Reveal Elements.
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
    Initializes the Reveal Element input.

    - Parameters:
        - token: A token to retrieve the value of.
        - inputStyles: Input styles for the Reveal Element.
        - labelStyles: Styles for the Reveal Element's label.
        - errorTextStyles: Styles for the Reveal Element's error text.
        - label: Label for the Reveal Element.
        - altText: Alternative text for the Reveal Element.
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
