import Foundation


class ConversionHelpers {
    static func convertJSONValues(_ requestBody: [String: Any], _ nested: Bool = true, _ arraySupport: Bool = true, contextOptions: ContextOptions) throws -> [String: Any] {
        var convertedRequest = [String: Any]()
        var errorCode = ErrorCodes.INVALID_DATA_TYPE_PASSED(value: "")
        for (key, value) in requestBody {
            do {
                convertedRequest[key] = try convertValue(value, nested, arraySupport, contextOptions: contextOptions)
            } catch {
                if error.localizedDescription == errorCode.description {
                    errorCode = .INVALID_DATA_TYPE_PASSED(value: key)
                    throw errorCode.getErrorObject(contextOptions: contextOptions)
                }
                throw error
            }
        }
        return convertedRequest
    }

    private static func convertValue(_ element: Any, _ nested: Bool, _ arraySupport: Bool, contextOptions: ContextOptions) throws -> Any {
        var errorCode: ErrorCodes?
        if checkIfPrimitive(element) {
            return element
        } else if arraySupport, element is [Any] {
            return try (element as! [Any]).map {
                try convertValue($0, nested, arraySupport, contextOptions: contextOptions)
            }
        } else if element is TextField {
            let textField = element as! TextField

            if textField.isValid() {
                return textField.getValue()
            } else {
                errorCode = .VALIDATIONS_FAILED()
                textField.updateErrorMessage()
                throw errorCode!.getErrorObject(contextOptions: contextOptions)
            }
        } else if element is Label {
            let label = element as! Label

            let result = label.getValue()
            if result.isEmpty {
                return label.getToken()
            } else {
                return result
            }
        } else if nested, element is [String: Any] {
            return try convertJSONValues(element as! [String: Any], nested, arraySupport, contextOptions: contextOptions)
        } else {
            errorCode = .INVALID_DATA_TYPE_PASSED(value: "")
            throw errorCode!.getErrorObject(contextOptions: contextOptions)
        }
    }

    static func convertOrFail(_ value: [String: Any]?, _ nested: Bool = true, _ arraySupport: Bool = true, contextOptions: ContextOptions) throws -> [String: Any]? {
        if let unwrappedValue = value {
            do {
                let convertedValue = try convertJSONValues(unwrappedValue, nested, arraySupport, contextOptions: contextOptions)
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

    static func checkElements(_ elements: [String: Any], _ duplicatesAllowed: Bool = false, emptyTokenAllowed: Bool = false, contextOptions: ContextOptions) throws {
        var traversedElements: [Any] = []
        var errorCode: ErrorCodes?

        func checkElement(_ key: String, _ element: Any) throws {
            if checkIfPrimitive(element) {
                return
            } else if element is [Any] {
                try (element as! [Any]).forEach {
                    try checkElement(key, $0)
                }
            } else if element is TextField {
                let textField = element as! TextField
                if !duplicatesAllowed, presentIn(traversedElements, value: element) {
                    errorCode = .DUPLICATE_ELEMENT_IN_RESPONSE_BODY(value: textField.collectInput.label)
                    throw errorCode!.getErrorObject(contextOptions: contextOptions)
                }
                if !(element as! TextField).isMounted() {
                    errorCode = .UNMOUNTED_ELEMENT_INVOKE_CONNECTION(value: textField.collectInput.column)
                    throw errorCode!.getErrorObject(contextOptions: contextOptions)
                }
                traversedElements.append(element)
            } else if element is Label {
                let label = element as! Label
                if !duplicatesAllowed, presentIn(traversedElements, value: element) {
                    errorCode = .DUPLICATE_ELEMENT_IN_RESPONSE_BODY(value: label.revealInput.label)
                    throw errorCode!.getErrorObject(contextOptions: contextOptions)
                }
                if !(element as! Label).isMounted() {
                    errorCode = .UNMOUNTED_ELEMENT_INVOKE_CONNECTION(value: label.revealInput.token)
                    throw errorCode!.getErrorObject(contextOptions: contextOptions)
                }
                if !emptyTokenAllowed && (element as! Label).actualValue.isEmpty && (element as! Label).getToken().isEmpty {
                    errorCode = .EMPTY_TOKEN_INVOKE_CONNECTION(value: key)
                    throw errorCode!.getErrorObject(contextOptions: contextOptions)
                }
                traversedElements.append(element)
            } else if element is [String: Any] {
                try checkDict((element as! [String: Any]))
            } else {
                errorCode = .INVALID_DATA_TYPE_PASSED(value: "")
                throw errorCode!.getErrorObject(contextOptions: contextOptions)
            }
        }

        func checkDict(_ dict: [String: Any]) throws {
            for (key, value) in dict {
                try checkElement(key, value)
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

    static func removeEmptyValuesFrom(response: [String: Any], contextOptions: ContextOptions) throws -> [String: Any] {
        var errorCode = ErrorCodes.INVALID_DATA_TYPE_PASSED(value: "")

        func recurseDict(_ dict: [String: Any]) throws -> [String: Any] {
            var result: [String: Any] = [:]
            for (key, value) in dict {
                do {
                    if let gottenValue = try getValue(value) {
                        result[key] = gottenValue
                    }
                } catch {
                    if error.localizedDescription == errorCode.description {
                        errorCode = .INVALID_DATA_TYPE_PASSED(value: key)
                        throw errorCode.getErrorObject(contextOptions: contextOptions)
                    }
                    throw error
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
                throw errorCode.getErrorObject(contextOptions: contextOptions)
            }
            return nil
        }

        return try recurseDict(response)
    }

    public static func stringifyDict(_ dict: [String: Any]?) -> [String: Any]? {
        if let values = dict {
            var result: [String: Any] = [:]
            for (key, value) in values {
                if value is String {
                    result[key] = value as! String
                } else if value is Int {
                    result[key] = String(value as! Int)
                } else if value is Double {
                    result[key] = String(value as! Double)
                } else if value is Bool {
                    result[key] = String(value as! Bool)
                } else if value is Array<Any> {
                    result[key] = value as! [Any]
                }
            }

            return result
        } else {
            return nil
        }
    }
}
