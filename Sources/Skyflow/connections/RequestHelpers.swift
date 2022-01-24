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
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers

        do {
            if let requestBody = body {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            }
        } catch {
            throw ErrorCodes.INVALID_REQUEST_BODY().getErrorObject(contextOptions: contextOptions)
        }


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
                        formattedValue = try formattedValue.getFirstRegexMatch(of: responseLabel.options.formatRegex)
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
}
