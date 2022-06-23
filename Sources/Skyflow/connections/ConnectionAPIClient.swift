/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation


class ConnectionAPIClient {
    var callback: Callback
    var contextOptions: ContextOptions

    internal init(callback: Callback, contextOptions: ContextOptions) {
        self.callback = callback
        self.contextOptions = contextOptions
    }

    internal func invokeConnection(token: String, config: ConnectionConfig) throws {
        let connectionRequestGroup = DispatchGroup()

        var isSuccess = true
        var errorObject: Error!
        
        var convertedResponse: [String: Any]?
        var stringResponse: String?
        var errors: [NSError] = []
        
        do {
            let (request, session) = try getRequestSession(config: config, token: token)

            connectionRequestGroup.enter()

            let task = session.dataTask(with: request) { data, response, error in
                defer {
                    connectionRequestGroup.leave()
                }
                do {
                    (convertedResponse, errors, stringResponse) = try self.processResponse(data: data, response: response, error: error, config: config)
                    if !errors.isEmpty {
                        isSuccess = false
                        errorObject = nil
                    }
                } catch {
                    isSuccess = false
                    errorObject = error
                    return
                }


            }
            task.resume()

            connectionRequestGroup.notify(queue: .main) {
                self.handleCallbacks(isSuccess: isSuccess, convertedResponse: convertedResponse, stringResponse: stringResponse, errors: errors, errorObject: errorObject)
            }
        } catch {
            throw error
        }
    }
    
    func getRequestSession(config: ConnectionConfig, token: String) throws -> (URLRequest, URLSession){
        let url = try RequestHelpers.createRequestURL(baseURL: config.connectionURL, pathParams: config.pathParams, queryParams: config.queryParams, contextOptions: self.contextOptions)
        var request = try RequestHelpers.createRequest(url: url, method: config.method, body: config.requestBody, headers: config.requestHeader, contextOptions: self.contextOptions)
        
        if !(RequestHelpers.getLowerCasedHeaders(headers: request.allHTTPHeaderFields).keys.contains("x-skyflow-authorization") ){
            request.setValue(token, forHTTPHeaderField: "x-skyflow-authorization")
        }

        return (request, URLSession(configuration: .default))
    }
    
    func processResponse(data: Data?, response: URLResponse?, error: Error?, config: ConnectionConfig) throws -> ([String: Any]?, [NSError], String?){
        
        var convertedResponse: [String: Any]?
        var stringResponse: String?
        var errors: [NSError] = []
        
        if error != nil {
            throw error!
        }

        if let httpResponse = response as? HTTPURLResponse {
            let range = 400...599
            if range ~= httpResponse.statusCode {
                var desc = "Invoke Connection call failed with the following status code " + String(httpResponse.statusCode)

                if let safeData = data {
                    desc = String(decoding: safeData, as: UTF8.self)
                }

                throw ErrorCodes.APIError(code: httpResponse.statusCode, message: desc).getErrorObject(contextOptions: self.contextOptions)
            }
        }


        if let safeData = data {
            let responseData = try JSONSerialization.jsonObject(with: safeData, options: .allowFragments)
            if responseData is [String: Any] {
                convertedResponse = try RequestHelpers.parseActualResponseAndUpdateElements(
                    response: responseData as! [String: Any],
                    responseBody: config.responseBody ?? [:],
                    contextOptions: self.contextOptions)
                errors = RequestHelpers.getInvalidResponseKeys(config.responseBody ?? [:], responseData as! [String : Any], contextOptions: self.contextOptions)
            } else if responseData is String {
                stringResponse = responseData as? String
            }
        }
        
        return (convertedResponse, errors, stringResponse)
    }
    
    func handleCallbacks(isSuccess: Bool, convertedResponse: [String: Any]?, stringResponse: String?, errors: [NSError], errorObject: Error?) {
        if isSuccess {
            do {
                if convertedResponse != nil {
                    let sanitizedResponse = try ConversionHelpers.removeEmptyValuesFrom(response: convertedResponse!, contextOptions: self.contextOptions)

                    self.callback.onSuccess(sanitizedResponse)
                } else if stringResponse != nil {
                    self.callback.onSuccess(stringResponse!)
                }
            } catch {
                self.callback.onFailure(error)
            }
        } else {
            if !errors.isEmpty {
                let failureResponse: [String: Any] = ["success": convertedResponse ?? [:], "errors": errors]
                self.callback.onFailure(failureResponse)
            } else {
                self.callback.onFailure(["errors": [errorObject!]])
            }
        }
    }
}
