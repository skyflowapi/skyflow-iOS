//
//  File.swift
//  
//
//  Created by Puneet Verma on 03/10/22.
//

import Foundation

package class ConversionHelpers {
    package static func checkElementsAreMounted(elements: [Any]) -> Any? {
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
