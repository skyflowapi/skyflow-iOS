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

    static func createRequestURL(baseURL: String, pathParams: [String: Any]?, queryParams: [String: Any]?) throws -> URL {
        var errorCode: ErrorCodes?
        guard ConversionHelpers.checkIfValuesArePrimitive(pathParams) else {
            errorCode = .INVALID_PATH_PARAMS()
            throw errorCode!.errorObject
        }
        guard ConversionHelpers.checkIfValuesArePrimitive(queryParams, true) else {
            errorCode = .INVALID_QUERY_PARAMS()
            throw errorCode!.errorObject
        }

        do {
            let URLWithPathParams = try addPathParams(baseURL, pathParams)
            if URL(string: URLWithPathParams) != nil {
                let finalURL = try addQueryParams(URLWithPathParams, queryParams)
                return finalURL
            } else {
                errorCode = .INVALID_PATH_PARAMS()
                throw errorCode!.errorObject
            }
        }
    }

    static func addPathParams(_ rawURL: String, _ pathParams: [String: Any]?) throws -> String {
        var URL = rawURL
        if pathParams != nil {
            for (param, value) in pathParams! {
                if let stringValue = value as? String {
                    URL = URL.replacingOccurrences(of: "{\(param)}", with: stringValue)
                } else {
                    throw ErrorCodes.INVALID_PATH_PARAMS().errorObject
                }
            }
        }
        return URL
    }

    static func addQueryParams(_ url: String, _ params: [String: Any]?) throws -> URL {
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
                    throw ErrorCodes.INVALID_QUERY_PARAMS().errorObject
                }
            }
        }
        if urlComponents?.url?.absoluteURL != nil {
            return (urlComponents?.url!.absoluteURL)!
        } else {
            throw ErrorCodes.INVALID_QUERY_PARAMS().errorObject
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
        } catch {
            throw ErrorCodes.INVALID_REQUEST_BODY().errorObject
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


    static func parseActualResponseAndUpdateElements(response: [String: Any], responseBody: [String: Any]) throws -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, _) in responseBody {
            if response[key] == nil {
                throw ErrorCodes.INVALID_RESPONSE_BODY().errorObject
            }

            do {
                let converted = try traverseAndConvert(response: response, responseBody: responseBody, key: key)
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

    static func traverseAndConvert(response: [String: Any], responseBody: [String: Any], key: String) throws -> Any? {
        if let value = response[key] {
            if let responseBodyValue = responseBody[key] {
                if ConversionHelpers.checkIfPrimitive(responseBodyValue) {
                    return value
                } else if responseBodyValue is TextField {
                    DispatchQueue.main.async {
                        (responseBodyValue as! TextField).textField.secureText = (value as! String)
                    }
                    return nil
                } else if responseBodyValue is Label {
                    DispatchQueue.main.async {
                        (responseBodyValue as! Label).updateVal(value: value as! String)
                    }
                    return nil
                } else if let valueDict = value as? [String: Any] {
                    return try parseActualResponseAndUpdateElements(response: valueDict, responseBody: responseBodyValue as! [String: Any])
                } else {
                    throw ErrorCodes.INVALID_RESPONSE_BODY().errorObject
                }
            } else {
                return value
            }
        }

        return nil
    }
}
