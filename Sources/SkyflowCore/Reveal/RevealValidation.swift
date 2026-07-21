/*
 * Copyright (c) 2026 Skyflow
*/

// Shared element-level validation used by Reveal containers, across all
// backends - identical regardless of which vault API the elements will
// eventually be revealed against.

import Foundation

public enum RevealValidation {
    public static func validateElements(_ elements: [Label]) -> ErrorCodes? {
        if let element = ConversionHelpers.checkElementsAreMounted(elements: elements) as? Label {
            return .UNMOUNTED_REVEAL_ELEMENT(value: element.revealInput.token)
        }
        for element in elements {
            if element.errorTriggered {
                return .ERROR_TRIGGERED(value: element.triggeredErrorMessage)
            }
            if element.getToken().isEmpty {
                return .EMPTY_TOKEN_ID()
            }
        }
        return nil
    }
}
