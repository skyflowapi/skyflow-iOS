import Foundation


class ConversionHelpers {
    static func convertJSONValues(_ requestBody: [String: Any], _ nested: Bool = true, _ arraySupport: Bool = true) throws -> [String: Any] {
        var convertedRequest = [String: Any]()
        do {
            for (key, value) in requestBody {
                convertedRequest[key] = try convertValue(value, nested, arraySupport)
            }
        } catch {
            throw error
        }
        return convertedRequest
    }

    private static func convertValue(_ element: Any, _ nested: Bool, _ arraySupport: Bool) throws -> Any {
        if checkIfPrimitive(element) {
            return element
        } else if arraySupport, element is [Any] {
            return try (element as! [Any]).map {
                try convertValue($0, nested, arraySupport)
            }
        } else if element is TextField {
            let textField = element as! TextField

            if textField.isValid() {
                return textField.getValue()
            } else {
                throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Validations failed for collect element with label '\(textField.textFieldLabel.text ?? "")'"])
            }
        } else if element is Label {
            let label = element as! Label

            return label.getValue()
        } else if nested, element is [String: Any] {
            return try convertJSONValues(element as! [String: Any], nested, arraySupport)
        } else {
            throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid type"])
        }
    }

    static func convertOrFail(_ value: [String: Any]?, _ nested: Bool = true, _ arraySupport: Bool = true) throws -> [String: Any]? {
        if let unwrappedValue = value {
            do {
                let convertedValue = try convertJSONValues(unwrappedValue, nested, arraySupport)
                return convertedValue
            }
        }

        return nil
    }

    static func checkIfPrimitive(_ element: Any) -> Bool {
        let supportedPrimitives: [Any.Type] = [String.self, Int.self, Double.self, Bool.self]

        for primitive in supportedPrimitives {
            if type(of: element) == primitive {
                return true
            }
        }

        return false
    }

    static func checkIfValuesArePrimitive(_ dict: [String: Any]?, _ arraySupport: Bool = false) -> Bool {
        if let unwrappedDict = dict {
            for (_, value) in unwrappedDict {
                let arraySupportCheck: Bool = (!arraySupport && value is [Any])
                if !checkIfPrimitive(value),
                   !(value is TextField),
                   !(value is Label),
                   arraySupportCheck {
                    return false
                }
            }
        }

        return true
    }

    static func convertParamArrays(params: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in params {
            if value is [Any] {
                let stringedValue: [String] = (value as! [Any]).compactMap { String(describing: $0) }
                result[key] = (stringedValue).joined(separator: ",")
            } else {
                result[key] = value
            }
        }

        return result
    }

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

    static func checkElements(_ elements: [String: Any], _ duplicatesAllowed: Bool = false) throws {
        var traversedElements: [Any] = []

        func checkElement(_ element: Any) throws {
            if checkIfPrimitive(element) {
                return
            } else if element is [Any] {
                try (element as! [Any]).forEach {
                        try checkElement($0)
                }
            } else if element is TextField {
                if !duplicatesAllowed, presentIn(traversedElements, value: element) {
                    throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Duplicate elements present"])
                }
                if !(element as! TextField).isMounted() {
                    throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Unmounted element present"])
                }
                traversedElements.append(element)
            } else if element is Label {
                if !duplicatesAllowed, presentIn(traversedElements, value: element) {
                    throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Duplicate elements present"])
                }
                if !(element as! Label).isMounted() {
                    throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Unmounted element present"])
                }
                traversedElements.append(element)
            } else if element is [String: Any] {
                try checkDict((element as! [String: Any]))
            } else {
                throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid type"])
            }
        }

        func checkDict(_ dict: [String: Any]) throws {
            for (_, value) in dict {
                try checkElement(value)
            }
        }


        try checkDict(elements)
    }

    static func presentIn(_ array: [Any], value: Any) -> Bool {
        for element in array {
            if element is TextField, value is TextField {
                if (element as! TextField) === (value as! TextField) {
                    return true
                }
            }
            if element is Label, value is Label {
                if  (element as! Label) === (value as! Label) {
                    return true
                }
            }
        }
        return false
    }

    static func removeEmptyValuesFrom(response: [String: Any])throws -> [String: Any] {
        func recurseDict(_ dict: [String: Any]) throws -> [String: Any] {
            var result: [String: Any] = [:]
            for (key, value) in dict {
                if let gottenValue = try getValue(value) {
                    result[key] = gottenValue
                }
            }

            return result
        }

        func getValue(_ value: Any) throws -> Any? {
            if value is String || value is Int || value is Double || value is Bool {
                return value
            } else if value is [Any] {
                if let arrayValue = value as? [Any], !arrayValue.isEmpty {
                    return arrayValue
                }
            } else if value is [String: Any] {
                if let dictValue = value as? [String: Any], !dictValue.isEmpty {
                    let dictResult = try recurseDict(dictValue)
                    if !dictResult.isEmpty {
                        return dictResult
                    }
                }
            } else {
                throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid value"])
            }
            return nil
        }

        return try recurseDict(response)
    }
}
