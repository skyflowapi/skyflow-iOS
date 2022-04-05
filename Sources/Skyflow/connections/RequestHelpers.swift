//
//  File.swift
//  
//
//  Created by Tejesh Reddy Allampati on 29/09/21.
//

import Foundation


class RequestHelpers {
    static var paths: [String] = []
    static var recursiveFailed = false
    

    static func createRequestURL(baseURL: String, pathParams: [String: Any]?, queryParams: [String: Any]?, contextOptions: ContextOptions) throws -> URL {
        var errorCode: ErrorCodes?
        guard ConversionHelpers.checkIfValuesArePrimitive(pathParams) else {
            errorCode = .INVALID_PATH_PARAMS()
            throw errorCode!.getErrorObject(contextOptions: contextOptions)
        }
        guard ConversionHelpers.checkIfValuesArePrimitive(queryParams, true) else {
            errorCode = .INVALID_QUERY_PARAMS()
            throw errorCode!.getErrorObject(contextOptions: contextOptions)
        }

        do {
            let URLWithPathParams = try addPathParams(baseURL, pathParams, contextOptions: contextOptions)
            if URL(string: URLWithPathParams) != nil {
                let finalURL = try addQueryParams(URLWithPathParams, queryParams, contextOptions: contextOptions)
                return finalURL
            } else {
                errorCode = .INVALID_PATH_PARAMS()
                throw errorCode!.getErrorObject(contextOptions: contextOptions)
            }
        }
    }

    static func addPathParams(_ rawURL: String, _ pathParams: [String: Any]?, contextOptions: ContextOptions) throws -> String {
        var URL = rawURL
        if pathParams != nil {
            for (param, value) in pathParams! {
                if let stringValue = value as? String, URL.contains("{" + param + "}") {
                    URL = URL.replacingOccurrences(of: "{\(param)}", with: stringValue)
                } else {
                    throw ErrorCodes.INVALID_PATH_PARAMS().getErrorObject(contextOptions: contextOptions)
                }
            }
        }
        return URL
    }

    static func addQueryParams(_ url: String, _ params: [String: Any]?, contextOptions: ContextOptions) throws -> URL {
        var urlComponents = URLComponents(string: removeTrailingSlash(url))


        if let queryParams = params {
            urlComponents?.queryItems = []

            for (param, value) in queryParams {
                if value is [Any] {
                    let stringedValues: [String] = (value as! [Any]).compactMap { String(describing: $0) }
                    for stringValue in stringedValues {
                        urlComponents?.queryItems?.append(URLQueryItem(name: param, value: stringValue))
                    }
                } else if let stringValue = value as? String {
                    urlComponents?.queryItems?.append(URLQueryItem(name: param, value: stringValue))
                } else {
                    throw ErrorCodes.INVALID_QUERY_PARAMS().getErrorObject(contextOptions: contextOptions)
                }
            }
        }
        if urlComponents?.url?.absoluteURL != nil {
            return (urlComponents?.url!.absoluteURL)!
        } else {
            throw ErrorCodes.INVALID_URL().getErrorObject(contextOptions: contextOptions)
        }
    }

    static func createRequest(url: URL, method: RequestMethod, body: [String: Any]?, headers: [String: String]?, contextOptions: ContextOptions) throws -> URLRequest {
        var request = URLRequest(url: url)
        
        if let unwrappedHeaders = headers {
            for (key, value) in unwrappedHeaders {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        if !(getLowerCasedHeaders(headers: request.allHTTPHeaderFields).keys.contains("content-type")){
            request.setValue("application/json", forHTTPHeaderField: "content-type")
        }

        do {
            if let requestBody = body {
                request = try getRequestByContentType(request, requestBody)
            }
        } catch {
            throw ErrorCodes.INVALID_REQUEST_BODY().getErrorObject(contextOptions: contextOptions)
        }
        
        request.httpMethod = method.rawValue
        
        return request
    }

    static func removeTrailingSlash(_ url: String) -> String {
        var result = url
        if url.hasSuffix("/") {
            result.removeLast()
        }
        return result
    }


    static func parseActualResponseAndUpdateElements(response: [String: Any], responseBody: [String: Any], contextOptions: ContextOptions) throws -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, _) in responseBody {
            if response[key] == nil {
                continue
            }

            do {
                let converted = try traverseAndConvert(response: response, responseBody: responseBody, key: key, contextOptions: contextOptions)
                if converted != nil {
                    result[key] = converted!
                }
            }
        }

        for (key, value) in response {
            if result[key] == nil, responseBody[key] == nil {
                result[key] = value
            }
        }


        return result
    }

    static func getInvalidResponseKeys(_ dict: [String: Any], _ response: [String: Any], contextOptions: ContextOptions) -> [NSError] {
        var result: [NSError] = []
        func goThroughDict(path: String, _ dict: [String: Any], _ response: [String: Any]) {
            for (key, value) in dict {
                if response[key] == nil {
                    result.append(ErrorCodes.MISSING_KEY_IN_RESPONSE(value: getPath(path, key)).getErrorObject(contextOptions: contextOptions))
                } else {
                    goThroughValues(path: getPath(path, key), value, response[key] as Any)
                }
            }
        }

        func goThroughValues(path: String, _ value: Any, _ response: Any) {
            if value is [String: Any], response is [String: Any] {
                goThroughDict(path: path, value as! [String: Any], response as! [String: Any])
            }
        }

        func getPath(_ path: String, _ key: String) -> String {
            if path.isEmpty {
                return key
            } else {
                return path + "." + key
            }
        }

        goThroughDict(path: "", dict, response)
        return result
    }

    static func traverseAndConvert(response: [String: Any], responseBody: [String: Any], key: String, contextOptions: ContextOptions) throws -> Any? {
        if let value = response[key] {
            if let responseBodyValue = responseBody[key] {
                if ConversionHelpers.checkIfPrimitive(responseBodyValue) {
                    return value
                } else if responseBodyValue is TextField {
                    DispatchQueue.main.async {
                        (responseBodyValue as! TextField).textField.secureText = (value as! String)
                        (responseBodyValue as! TextField).updateActualValue()
                    }
                    return nil
                } else if responseBodyValue is Label {
                    let responseLabel = (responseBodyValue as! Label)
                    var formattedValue = (value as! String)
                    if !responseLabel.options.formatRegex.isEmpty {
                        formattedValue = formattedValue.getFormattedText(with: responseLabel.options.formatRegex, replacementString: responseLabel.options.replaceText, contextOptions: contextOptions)
                    }
                    DispatchQueue.main.async {
                        responseLabel.updateVal(value: formattedValue)
                    }
                    return nil
                } else if let valueDict = value as? [String: Any] {
                    return try parseActualResponseAndUpdateElements(response: valueDict, responseBody: responseBodyValue as! [String: Any], contextOptions: contextOptions)
                } else {
                    throw ErrorCodes.INVALID_RESPONSE_BODY().getErrorObject(contextOptions: contextOptions)
                }
            } else {
                return value
            }
        }

        return nil
    }
    
    class func getRequestByContentType(_ request: URLRequest, _ body: [String: Any]) throws -> URLRequest {
        guard let headers = request.allHTTPHeaderFields else {
            return request
        }
        guard let contentType = headers["Content-Type"] else {
            return request
        }
        var resultRequest = request
        switch contentType {
        case SupportedContentTypes.FORMDATA.rawValue:
            var parents = [] as [Any]
            var pairs = [:] as [String: String]
            let encodedJson = UrlEncoder.encodeByType(parents: &parents, pairs: &pairs, data: body)
            let multipartRequest = MultipartFormDataRequest(url: request.url!)
            multipartRequest.addValues(json: encodedJson)
            resultRequest = multipartRequest.asURLRequest(with: headers)
        case SupportedContentTypes.URLENCODED.rawValue:
            resultRequest.httpBody = UrlEncoder.encode(json: body).data(using: .utf8)
        default:
            resultRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        return resultRequest
    }
    
    static func getLowerCasedHeaders(headers: [String: String]?) -> [String: String] {
        
        var lowerCasedHeaders = [:] as [String: String]
        
        if let unwrappedHeaders = headers {
            for (key, value) in unwrappedHeaders {
                lowerCasedHeaders[key.lowercased()] = value
            }
        }
        
        return lowerCasedHeaders
    }
}

enum SupportedContentTypes: String {
    case URLENCODED = "application/x-www-form-urlencoded"
    case FORMDATA = "multipart/form-data"
    case JSON = "application/json"
}
