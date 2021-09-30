//
//  File.swift
//  
//
//  Created by Tejesh Reddy Allampati on 29/09/21.
//

import Foundation


class RequestHelpers {
    static var paths: [String] = []
    static var recursiveFailed: Bool = false
    static func createRequest(baseURL: String, pathParams: [String: Any], queryParams: [String: Any]) throws -> URL {
        guard !ConversionHelpers.checkIfValuesArePrimitive(pathParams) else {
            throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid path params"])
        }
        guard !ConversionHelpers.checkIfValuesArePrimitive(queryParams) else {
            throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid query params"])
        }
        
        do {
            let URLWithPathParams = try addPathParams(baseURL, pathParams)
            if URL(string: URLWithPathParams) != nil{
                let finalURL = try addQueryParams(URLWithPathParams, queryParams)
                return finalURL
            }
            else {
                throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid path params"])
            }
        }
    }
    
    static func addPathParams(_ rawURL: String, _ pathParams: [String: Any]) throws -> String {
        var URL = rawURL
        for (param, value) in pathParams {
            if let stringValue = value as? String {
                URL = URL.replacingOccurrences(of: "{\(param)}", with: stringValue)
            }
            else {
                throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "addPathParams"])
            }
        }
        
        return URL
    }
    
    static func addQueryParams(_ url: String, _ queryParams: [String: Any]) throws -> URL {
        var urlComponents = URLComponents(string: removeTrailingSlash(url))
        
        urlComponents?.queryItems = []
        
        for (param, value) in queryParams {
            if let stringValue = value as? String {
                urlComponents?.queryItems?.append(URLQueryItem(name: param, value: stringValue))
            }
            else {
                throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "addQueryParams"])
            }
        }
        
        if urlComponents?.url?.absoluteURL != nil {
            return (urlComponents?.url!.absoluteURL)!
        }
        else {
            throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid Query params"])
        }
        
    }
    
    static func removeTrailingSlash(_ url: String) -> String{
        var result = url
        if url.hasSuffix("/") {
            result.removeLast()
        }
        return result
    }
    
    static func parseResponse(response: [String: Any]) -> [String]{
        paths = []
        recursiveFailed = false
        for (key, value) in response {
            if let valueDict = value as? [String: Any]{
                traverseResponseRecursively(currPath: key, response: valueDict)
            }
            else if value is TextField {
                paths.append(key)
            }
            else if value is Label {
                paths.append(key)
            }
            else {
                print("Throw error/Call onfailure, invalid element")
            }
        }
        return paths
    }
    
    static func traverseResponseRecursively(currPath: String, response: [String: Any]){
        if(!recursiveFailed){
            for (key, value) in response {
                if let valueDict = value as? [String: Any]{
                    traverseResponseRecursively(currPath: currPath + "." + key, response: valueDict)
                }
                else if value is TextField {
                    paths.append(currPath + "." + key)
                }
                else if value is Label {
                    paths.append(currPath + "." + key)
                }
                else {
                    print("Throw error/Call onfailure, invalid element")
                }
            }
        }
    }
    
//    static func validateResponse(response: [String: Any]) -> Bool{
//        var isValid: Bool = true
//        for (key, value) in response {
//            if let valueDict = value as? [String: Any]{
//                isValid = isValid && validateResponse(response: valueDict)
//            }
//            else{
//
//            }
//        }
//        return isValid
//    }
    
    static func verifyAllPathsInResponse(paths: [String], response: [String: Any]) -> Bool{
        for path in paths {
            if response[keyPath: path] == nil {
                return false
            }
        }
        return true
    }
    
    static func updateElementsWithResponse(paths: [String], response: [String: Any], responseBody: [String: Any]){
        //Might need to check for dupes, or unexpected value will be updated
        for path in paths {
            if(responseBody[keyPath: path] != nil && response[keyPath: path] != nil){
                let element = responseBody[keyPath: path]
                if element is TextField {
                    (element as! TextField).textField.secureText = response[keyPath: path] as? String
                }
                else if element is Label {
                    (element as! Label).skyflowLabelView.label.secureText = response[keyPath: path] as? String
                }
                else{
                    print("throw error update element failed")
                }
            }
        }
    }
}
