/*
 * Copyright (c) 2022 Skyflow
*/

// An Object that describes SkyflowInputField (FlowVault contract:
// `tableName:` and `skyflowId:` argument labels). A struct: elements store
// their own copy, so reusing one input never shares state.

import Foundation

public struct CollectElementInput {
    package var data: BaseCollectElementInput

    public init(tableName: String = "", column: String = "",
                inputStyles: Styles? = Styles(), labelStyles: Styles? = Styles(), errorTextStyles: Styles? = Styles(), iconStyles: Styles? = Styles(), label: String? = "",
                placeholder: String? = "", validations: ValidationSet=ValidationSet(), skyflowId: String? = nil) {
        self.data = BaseCollectElementInput(tableName: tableName, column: column, inputStyles: inputStyles!, labelStyles: labelStyles!, errorTextStyles: errorTextStyles!, iconStyles: iconStyles!, label: label!, placeholder: placeholder!, type: nil, validations: validations, skyflowId: skyflowId)
    }

    public init(tableName: String = "", column: String = "",
                inputStyles: Styles? = Styles(), labelStyles: Styles? = Styles(), errorTextStyles: Styles? = Styles(), iconStyles: Styles? = Styles(), label: String? = "",
                placeholder: String? = "", type: ElementType?, validations: ValidationSet=ValidationSet(), skyflowId: String? = nil) {
        self.data = BaseCollectElementInput(tableName: tableName, column: column, inputStyles: inputStyles!, labelStyles: labelStyles!, errorTextStyles: errorTextStyles!, iconStyles: iconStyles!, label: label!, placeholder: placeholder!, type: type, validations: validations, skyflowId: skyflowId)
    }

    @available(*, deprecated, message: "altText param is deprecated")
    public init(tableName: String = "", column: String = "",
            inputStyles: Styles? = Styles(), labelStyles: Styles? = Styles(), errorTextStyles: Styles? = Styles(), iconStyles: Styles? = Styles(), label: String? = "",
            placeholder: String? = "", altText: String? = "", type: ElementType?, validations: ValidationSet=ValidationSet(), skyflowId: String? = nil) {
        self.data = BaseCollectElementInput(tableName: tableName, column: column, inputStyles: inputStyles!, labelStyles: labelStyles!, errorTextStyles: errorTextStyles!, iconStyles: iconStyles!, label: label!, placeholder: placeholder!, type: type, validations: validations, skyflowId: skyflowId)
    }
}

public extension TextField {
    func update(update: CollectElementInput) {
        self.update(data: update.data)
    }
}
