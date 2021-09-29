import Foundation


class ConversionHelpers {
    static func convertJSONValues(_ requestBody: [String: Any], _ nested: Bool = true) throws -> [String: Any] {
        var convertedRequest = [String: Any]()
        do {
            for (key, value) in requestBody {
                convertedRequest[key] = try convertValue(value, nested)
            }
        }
        catch {
            throw error
        }
        return convertedRequest
    }

    private static func convertValue(_ element: Any, _ nested: Bool) throws -> Any{
        if checkIfPrimitive(element) || element is Array<Any> {
            return element
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

    static func convertOrFail(_ value: [String: Any]?, _ nested: Bool = true) throws -> [String: Any]?{
        
        if let unwrappedValue = value {
            do {
                let convertedValue = try convertJSONValues(unwrappedValue, nested)
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
}
