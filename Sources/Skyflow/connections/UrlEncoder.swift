import Foundation


internal class UrlEncoder {
    /// Encodes the given json to application/x-www-form-urlencoded request body format
    ///
    /// - Parameter json: a dictionary that represents json data
    /// - Returns: A url-encoded string of given `json` value
    class func encode(json: [String: Any]) -> String {
        var parents = [] as [Any]
        var pairs = [:] as [String: String]
        let simpleJSON = encodeByType(parents: &parents, pairs: &pairs, data: json)
        
        return encodeSimpleJson(json: simpleJSON)
    }
    
    
    /// Encodes a json to applicaton/www-form-urlencoded request body format by type of values by
    /// converting to php style associative array recursively
    ///
    /// - Parameter parents: A  list of initial parent values
    /// - Parameter pairs: An initial dictionary of result, it will be populated by encoding `data`
    /// - Parameter data: The data to be encoded
    /// - Returns: A url-encoded string of given `json`
    class func encodeByType(parents: inout [Any], pairs: inout [String: String], data: Any) -> [String: String] {
        
        var parents = parents
        
        if let array = data as? [Any] {
            for i in 0...array.count {
                parents.append(i)
                encodeByType(parents: &parents, pairs: &pairs, data: array[i])
                parents.removeLast()
            }
        } else if let dict = data as? [String: Any] {
            for (key, value) in dict {
                parents.append(key)
                encodeByType(parents: &parents, pairs: &pairs, data: value)
                parents.removeLast()
            }
        } else {
            pairs[encodeKey(parents)] = "\(data)"
        }
        
                
        return pairs
    }
    
    /// Encodes a key to php style associative array key
    ///
    /// - Parameter parents: A non-nested dictionary with only primitive values
    /// - Returns: A url-encoded string of given `json`
    class func encodeKey(_ parents: [Any]) -> String {
        
        var depth = 0
        var result = ""
        
        for parent in parents{
            var idx = ""
            if depth > 0 {
                idx = "[\(parent)]"
            } else {
                idx = "\(parent)"
            }
            
            result += idx
            depth += 1
        }
        
        return result
    }
    
    class func encodeSimpleJson(json: [String: String]) -> String {
        return String(json.reduce("") {
            "\($0)\($1.0)=\($1.1)&"
        }.dropLast())
    }
}
