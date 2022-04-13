//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 24/12/21.
//

import Foundation

public class SoapConnectionAPIClient {
    var callback: Callback
    var contextOptions: ContextOptions
    var skyflow: Client

    internal init(callback: Callback, skyflow: Client, contextOptions: ContextOptions) {
        self.callback = callback
        self.contextOptions = contextOptions
        self.skyflow = skyflow
    }
    
    internal func invokeSoapConnection(token: String, config: SoapConnectionConfig) throws {
        
        let semaphore = DispatchSemaphore(value: 0)
        var errorObject: Error?
        
        var parameters = ""
        let url = URL(string: config.connectionURL)
        if url == nil {
            let errorCode = ErrorCodes.INVALID_CONNECTION_URL(value: config.connectionURL)
            return callback.onFailure(errorCode.getErrorObject(contextOptions: contextOptions))
        }
        do {
            var request = try self.constructRequest(url: url!, requestXML: config.requestXML, headers: config.httpHeaders, token: token)
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                
                defer {
                    semaphore.signal()
                }
                var newActualResponse: String = ""
                do {
                    newActualResponse = try self.processResponse(data: data, response: response, error: error, responseXML: config.responseXML)
                }
                catch {
                    errorObject = error
                    return
                }
                
                self.callback.onSuccess(newActualResponse)
            }

            task.resume()
            semaphore.wait()
            
            if(errorObject != nil) {
                self.callback.onFailure(errorObject)
            }
        }
        catch {
            return callback.onFailure(error)
        }
    }
    
    func constructApiError(data: Data, _ httpResponse: HTTPURLResponse) -> SkyflowError? {
        let desc = "Invoke Connection call failed with the following status code " + String(httpResponse.statusCode)

        let skyflowError = ErrorCodes.APIError(code: httpResponse.statusCode, message: desc).getErrorObject(contextOptions: self.contextOptions) as? SkyflowError
        skyflowError?.setXML(xml: String(data: data, encoding: .utf8) ?? "")
        return skyflowError
    }

    func processResponse(data: Data?, response: URLResponse?, error: Error?, responseXML: String) throws -> String{
        guard let data = data else {
            throw error!
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            let range = 400...599
            if range ~= httpResponse.statusCode {
                throw self.constructApiError(data: data, httpResponse)!
            }
        }
        return try SoapRequestHelpers.handleXMLResponse(
            responseXML: responseXML,
            actualResponse: String(data: data, encoding: .utf8)!,
            skyflow: self.skyflow,
            contextOptions: self.contextOptions)
    }
    
    func constructRequest(url: URL, requestXML: String, headers: [String: String], token: String) throws -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: .infinity)
        
        let parameters = try SoapRequestHelpers.replaceElementsInXML(xml: requestXML, skyflow: skyflow, contextOptions: contextOptions)
        
        let postData = parameters.data(using: .utf8)
        
        var lowerCasedHeaders: [String] = []
        
        for (key, val) in headers {
            request.setValue(val, forHTTPHeaderField: key)
            lowerCasedHeaders.append(key.lowercased())
        }
        
        if !(lowerCasedHeaders.contains("X-Skyflow-Authorization".lowercased())) {
            request.setValue(token, forHTTPHeaderField: "X-Skyflow-Authorization")
        }
        
        if !(lowerCasedHeaders.contains("Content-Type".lowercased())) {
            request.setValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }


        request.httpMethod = "POST"
        request.httpBody = postData
        
        return request

    }

}
