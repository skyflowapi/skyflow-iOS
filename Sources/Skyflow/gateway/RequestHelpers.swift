//
//  File.swift
//  
//
//  Created by Tejesh Reddy Allampati on 29/09/21.
//

import Foundation


class RequestHelpers {
    static func createRequest(baseURL: String, pathParams: [String: Any], queryParams: [String: Any]) throws{
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
}
