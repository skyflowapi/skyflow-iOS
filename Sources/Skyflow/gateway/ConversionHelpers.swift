import Foundation


class ConversionHelpers {
    static func convertJSONValues(_ requestBody: [String: Any], _ nested: Bool = true, _ arraySupport: Bool = true) throws -> [String: Any] {
        var convertedRequest = [String: Any]()
        do {
            for (key, value) in requestBody {
                convertedRequest[key] = try convertValue(value, nested, arraySupport)
            }
        }
        catch {
            throw error
        }
        return convertedRequest
    }

    private static func convertValue(_ element: Any, _ nested: Bool, _ arraySupport: Bool) throws -> Any{
        if checkIfPrimitive(element) {
            return element
        }
        else if arraySupport, element is Array<Any> {
            return try (element as! Array<Any>).map{
                try convertValue($0, nested, arraySupport)
            }
        }
        else if element is TextField {
            return (element as! TextField).getValue()
        }
        else if element is Label {
            return (element as! Label).getValue()
        }
        else if nested, element is [String: Any] {
            return try! convertJSONValues(element as! [String: Any])
        }
        else {
            throw NSError(domain: "Invalid type", code: 400)
        }
    }

    static func convertOrFail(_ value: [String: Any]?, _ nested: Bool = true, _ arraySupport: Bool = true) throws -> [String: Any]?{
        
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
            for (key, value) in unwrappedDict {
                let arraySupportCheck: Bool = (!arraySupport && value is Array<Any>)
                if !checkIfPrimitive(value),
                   !(value is TextField),
                   !(value is Label),
                   arraySupportCheck{
                    return false
                }
            }
        }
        
        return true
    }
    
    static func convertParamArrays(params: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in params {
            if value is Array<Any> {
                let stringedValue: [String] = (value as! [Any]).compactMap{ String(describing: $0) }
                result[key] = (stringedValue).joined(separator: ",")
            }
            else {
                result[key] = value
            }
        }
        
        return result
    }
}
