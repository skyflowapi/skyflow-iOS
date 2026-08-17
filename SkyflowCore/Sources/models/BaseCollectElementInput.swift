/*
 * Copyright (c) 2022 Skyflow
*/

// Shared storage for the collect element input. Each SDK product defines its
// own public `CollectElementInput` struct exposing that contract's
// initializers (the legacy SDK uses `table:`/`skyflowID:` argument labels,
// FlowVault uses `tableName:`/`skyflowId:`); those structs wrap this value and
// hand it to the core element factories. Value semantics: every element stores
// its own copy, so post-creation mutations never leak between elements.

import Foundation

package struct BaseCollectElementInput {
    package var tableName: String
    package var column: String
    package var inputStyles: Styles
    package var labelStyles: Styles
    package var errorTextStyles: Styles
    package var iconStyles: Styles
    package var label: String
    package var placeholder: String
    package var type: ElementType?
    package var validations: ValidationSet
    package var skyflowId: String?

    package init(tableName: String, column: String, inputStyles: Styles, labelStyles: Styles, errorTextStyles: Styles, iconStyles: Styles, label: String, placeholder: String, type: ElementType?, validations: ValidationSet, skyflowId: String?) {
        self.tableName = tableName
        self.column = column
        self.inputStyles = inputStyles
        self.labelStyles = labelStyles
        self.errorTextStyles = errorTextStyles
        self.iconStyles = iconStyles
        self.label = label
        self.placeholder = placeholder
        self.type = type
        self.validations = validations
        self.skyflowId = skyflowId
    }
}
