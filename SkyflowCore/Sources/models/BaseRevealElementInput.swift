/*
 * Copyright (c) 2022 Skyflow
*/

// Shared storage for the reveal element input. Each SDK product defines its
// own public `RevealElementInput` struct exposing that contract's initializers
// (the legacy SDK includes a per-token `redaction:` parameter; FlowVault does
// not); those structs wrap this value and hand it to the core element
// factories. Value semantics: every element stores its own copy, so
// post-creation mutations (setToken/setAltText) never leak between elements.

import Foundation

package struct BaseRevealElementInput {
    package var token: String
    package var inputStyles: Styles?
    package var labelStyles: Styles?
    package var errorTextStyles: Styles?
    package var label: String
    // Per-token redaction is only surfaced (and sent on the wire) by the
    // legacy SDK; FlowVault leaves the default and uses tokenGroupRedactions.
    package var redaction: RedactionType
    package var altText: String

    package init(token: String, inputStyles: Styles, labelStyles: Styles, errorTextStyles: Styles, label: String, redaction: RedactionType, altText: String) {
        self.token = token
        self.inputStyles = inputStyles
        self.labelStyles = labelStyles
        self.errorTextStyles = errorTextStyles
        self.label = label
        self.redaction = redaction
        self.altText = altText
    }
}
