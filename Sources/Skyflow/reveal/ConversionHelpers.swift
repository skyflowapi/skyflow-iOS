/*
 * Copyright (c) 2022 Skyflow
 */

import Foundation

class ConversionHelpers {
    static func checkElementsAreMounted(elements: [Any]) -> Any? {
        for element in elements {
            if let label = element as? Label, !label.isMounted() {
                return label
            } else if let textField = element as? TextField, !textField.isMounted() {
                return textField
            }
        }
        return nil
    }
}
