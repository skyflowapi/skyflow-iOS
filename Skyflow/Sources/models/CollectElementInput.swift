/*
 * Copyright (c) 2022 Skyflow
*/

// An Object that describes SkyflowInputField (legacy contract: `table:` and
// `skyflowID:` argument labels, exactly as released). A struct, as on main:
// elements store their own copy, so reusing one input never shares state.

import Foundation

public struct CollectElementInput {
    package var data: BaseCollectElementInput
    // Set only by the file initializer; read by create(fileInput:).
    internal var fileInput: FileElementInput?

    /// A file element (`type: .FILE_INPUT` or `.MULTI_FILE_INPUT`), as in skyflow-js. Create it
    /// with `container.create(fileInput:options:)`.
    ///
    /// - Parameters:
    ///   - table: Table that receives the file. Required.
    ///   - column: File column. Required.
    ///   - placeholder: Title of the `.FIELD` button. Defaults to "Choose File"
    ///     ("Choose Files" for `.MULTI_FILE_INPUT`).
    ///   - type: `.FILE_INPUT` or `.MULTI_FILE_INPUT`.
    ///   - skyflowID: Attach the file to this existing record instead of creating a new one.
    ///     Supported for `.FILE_INPUT` only.
    ///   - appearance: How the element looks. Defaults to `.FIELD`. Use `.CUSTOM` to open the
    ///     picker from the app's own control with `FileInputElement.openPicker()`. `inputStyles`
    ///     styles the `.FIELD` box, or the file names with `.CUSTOM`.
    public init(table: String = "", column: String = "",
                inputStyles: Styles = Styles(), labelStyles: Styles = Styles(), errorTextStyles: Styles = Styles(),
                label: String = "", placeholder: String = "",
                type: FileElementType, skyflowID: String? = nil,
                appearance: FileElementAppearance = .FIELD) {
        self.data = BaseCollectElementInput(tableName: table, column: column, inputStyles: inputStyles, labelStyles: labelStyles, errorTextStyles: errorTextStyles, iconStyles: Styles(), label: label, placeholder: placeholder, type: nil, validations: ValidationSet(), skyflowId: skyflowID)
        self.fileInput = FileElementInput(table: table, column: column, inputStyles: inputStyles, labelStyles: labelStyles,
                                          errorTextStyles: errorTextStyles, label: label, placeholder: placeholder,
                                          type: type, skyflowID: skyflowID, appearance: appearance)
    }

    public init(table: String = "", column: String = "",
                inputStyles: Styles? = Styles(), labelStyles: Styles? = Styles(), errorTextStyles: Styles? = Styles(), iconStyles: Styles? = Styles(), label: String? = "",
                placeholder: String? = "", validations: ValidationSet=ValidationSet(), skyflowID: String? = "") {
        self.data = BaseCollectElementInput(tableName: table, column: column, inputStyles: inputStyles ?? Styles(), labelStyles: labelStyles ?? Styles(), errorTextStyles: errorTextStyles ?? Styles(), iconStyles: iconStyles ?? Styles(), label: label ?? "", placeholder: placeholder ?? "", type: nil, validations: validations, skyflowId: skyflowID)
    }

    public init(table: String = "", column: String = "",
                inputStyles: Styles? = Styles(), labelStyles: Styles? = Styles(), errorTextStyles: Styles? = Styles(), iconStyles: Styles? = Styles(), label: String? = "",
                placeholder: String? = "", type: ElementType?, validations: ValidationSet=ValidationSet(), skyflowID: String? = "") {
        self.data = BaseCollectElementInput(tableName: table, column: column, inputStyles: inputStyles ?? Styles(), labelStyles: labelStyles ?? Styles(), errorTextStyles: errorTextStyles ?? Styles(), iconStyles: iconStyles ?? Styles(), label: label ?? "", placeholder: placeholder ?? "", type: type, validations: validations, skyflowId: skyflowID)
    }

    @available(*, deprecated, message: "altText param is deprecated")
    public init(table: String = "", column: String = "",
            inputStyles: Styles? = Styles(), labelStyles: Styles? = Styles(), errorTextStyles: Styles? = Styles(), iconStyles: Styles? = Styles(), label: String? = "",
            placeholder: String? = "", altText: String? = "", type: ElementType?, validations: ValidationSet=ValidationSet(), skyflowID: String? = "") {
        self.data = BaseCollectElementInput(tableName: table, column: column, inputStyles: inputStyles ?? Styles(), labelStyles: labelStyles ?? Styles(), errorTextStyles: errorTextStyles ?? Styles(), iconStyles: iconStyles ?? Styles(), label: label ?? "", placeholder: placeholder ?? "", type: type, validations: validations, skyflowId: skyflowID)
    }
}

public extension TextField {
    func update(update: CollectElementInput) {
        self.update(data: update.data)
    }
}
