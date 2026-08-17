/*
 * Copyright (c) 2022 Skyflow
*/

// Object for reveal element (FlowVault contract: no per-token redaction;
// redaction is controlled via tokenGroupRedactions on reveal()). A struct:
// elements store their own copy, so reusing one input never shares state.

import Foundation

public struct RevealElementInput {
    package var data: BaseRevealElementInput

    public init(token: String = "", inputStyles: Styles = Styles(), labelStyles: Styles = Styles(), errorTextStyles: Styles = Styles(), label: String, altText: String = "") {
        self.data = BaseRevealElementInput(token: token, inputStyles: inputStyles, labelStyles: labelStyles, errorTextStyles: errorTextStyles, label: label, redaction: .PLAIN_TEXT, altText: altText)
    }
}
