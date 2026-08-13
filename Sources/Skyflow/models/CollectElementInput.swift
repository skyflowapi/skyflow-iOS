/*
 * Copyright (c) 2022 Skyflow
*/

// An Object that describes SkyflowInputField (legacy contract: `table:` and
// `skyflowID:` argument labels, exactly as released). A struct, as on main:
// elements store their own copy, so reusing one input never shares state.

import Foundation

public struct CollectElementInput {
    package var data: BaseCollectElementInput

    public init(table: String = "", column: String = "",
                inputStyles: Styles? = Styles(), labelStyles: Styles? = Styles(), errorTextStyles: Styles? = Styles(), iconStyles: Styles? = Styles(), label: String? = "",
                placeholder: String? = "", validations: ValidationSet=ValidationSet(), skyflowID: String? = "") {
        self.data = BaseCollectElementInput(tableName: table, column: column, inputStyles: inputStyles!, labelStyles: labelStyles!, errorTextStyles: errorTextStyles!, iconStyles: iconStyles!, label: label!, placeholder: placeholder!, type: nil, validations: validations, skyflowId: skyflowID)
    }

    public init(table: String = "", column: String = "",
                inputStyles: Styles? = Styles(), labelStyles: Styles? = Styles(), errorTextStyles: Styles? = Styles(), iconStyles: Styles? = Styles(), label: String? = "",
                placeholder: String? = "", type: ElementType?, validations: ValidationSet=ValidationSet(), skyflowID: String? = "") {
        self.data = BaseCollectElementInput(tableName: table, column: column, inputStyles: inputStyles!, labelStyles: labelStyles!, errorTextStyles: errorTextStyles!, iconStyles: iconStyles!, label: label!, placeholder: placeholder!, type: type, validations: validations, skyflowId: skyflowID)
    }

    @available(*, deprecated, message: "altText param is deprecated")
    public init(table: String = "", column: String = "",
            inputStyles: Styles? = Styles(), labelStyles: Styles? = Styles(), errorTextStyles: Styles? = Styles(), iconStyles: Styles? = Styles(), label: String? = "",
            placeholder: String? = "", altText: String? = "", type: ElementType?, validations: ValidationSet=ValidationSet(), skyflowID: String? = "") {
        self.data = BaseCollectElementInput(tableName: table, column: column, inputStyles: inputStyles!, labelStyles: labelStyles!, errorTextStyles: errorTextStyles!, iconStyles: iconStyles!, label: label!, placeholder: placeholder!, type: type, validations: validations, skyflowId: skyflowID)
    }
}

public extension TextField {
    func update(update: CollectElementInput) {
        self.update(data: update.data)
    }
}
