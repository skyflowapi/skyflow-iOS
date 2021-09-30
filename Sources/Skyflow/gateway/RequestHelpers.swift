//
//  File.swift
//  
//
//  Created by Tejesh Reddy Allampati on 29/09/21.
//

import Foundation


class RequestHelpers {
    static func createRequestURL(baseURL: String, pathParams: [String: Any]?, queryParams: [String: Any]?) throws -> URL{
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
    
    static func addPathParams(_ rawURL: String, _ pathParams: [String: Any]?) throws -> String {
        var URL = rawURL
        if pathParams != nil {
            for (param, value) in pathParams! {
                if let stringValue = value as? String {
                    URL = URL.replacingOccurrences(of: "{\(param)}", with: stringValue)
                }
                else {
                    throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "addPathParams"])
                }
            }
        }
        return URL
    }
    
    static func addQueryParams(_ url: String, _ queryParams: [String: Any]?) throws -> URL {
        var urlComponents = URLComponents(string: removeTrailingSlash(url))
        
        urlComponents?.queryItems = []
        
        if queryParams != nil {
            for (param, value) in queryParams! {
                if let stringValue = value as? String {
                    urlComponents?.queryItems?.append(URLQueryItem(name: param, value: stringValue))
                }
                else {
                    throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "addQueryParams"])
                }
            }
        }
        if urlComponents?.url?.absoluteURL != nil {
            return (urlComponents?.url!.absoluteURL)!
        }
        else {
            throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid Query params"])
        }
        
    }
    
    static func createRequest(url: URL, method: RequestMethod, body: [String: Any]?, headers: [String: String]?) throws -> URLRequest {
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        
        do {
            if let requestBody = body {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            }
        }
        catch {
            throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid request body"])
        }
        
        
        return request
        
    }
    
    static func removeTrailingSlash(_ url: String) -> String{
        var result = url
        if url.hasSuffix("/") {
            result.removeLast()
        }
        return result
    }
}
