/*
 * Copyright (c) 2022 Skyflow
*/

// What a file element stores. Apps describe a file element with `CollectElementInput`
// (`type: .FILE_INPUT`), as in skyflow-js; this is its internal form.

import Foundation

internal struct FileElementInput {
    internal var table: String
    internal var column: String
    internal var inputStyles: Styles
    internal var labelStyles: Styles
    internal var errorTextStyles: Styles
    internal var label: String
    internal var placeholder: String
    internal var type: FileElementType
    internal var skyflowID: String?
    internal var appearance: FileElementAppearance
    // Set when the input passed to create(fileInput:) is not a file type.
    internal var isNotFileType = false

    /// - Parameters:
    ///   - table: Table that receives the file. Required.
    ///   - column: File column. Required.
    ///   - placeholder: Title of the `.FIELD` button. Defaults to "Choose File"
    ///     ("Choose Files" for `.MULTI_FILE_INPUT`).
    ///   - type: `.FILE_INPUT` or `.MULTI_FILE_INPUT`.
    ///   - skyflowID: Attach the file to this existing record instead of creating a new one.
    ///     Supported for `.FILE_INPUT` only.
    ///   - appearance: How the element looks. Defaults to `.FIELD`. `inputStyles` styles the
    ///     `.FIELD` box, or the file names with `.CUSTOM`.
    init(table: String = "", column: String = "",
                inputStyles: Styles = Styles(), labelStyles: Styles = Styles(), errorTextStyles: Styles = Styles(),
                label: String = "", placeholder: String = "",
                type: FileElementType, skyflowID: String? = nil,
                appearance: FileElementAppearance = .FIELD) {
        self.table = table
        self.column = column
        self.inputStyles = inputStyles
        self.labelStyles = labelStyles
        self.errorTextStyles = errorTextStyles
        self.label = label
        self.placeholder = placeholder
        self.type = type
        self.skyflowID = skyflowID
        self.appearance = appearance
    }
}
