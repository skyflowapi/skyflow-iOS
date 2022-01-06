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
        var request = URLRequest(url: url!,timeoutInterval: Double.infinity)

        do {
            
            parameters = try SoapRequestHelpers.replaceElementsInXML(xml: config.requestXML, skyflow: skyflow, contextOptions: contextOptions)
        }
        catch {
            return callback.onFailure(error)
        }

        let postData = parameters.data(using: .utf8)

        if config.httpHeaders["Content-Type"] == nil {
            request.addValue("text/xml; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
        for (key, val) in config.httpHeaders {
            request.addValue(val, forHTTPHeaderField: key)
        }

        request.addValue(token, forHTTPHeaderField: "X-Skyflow-Authorization")

        request.httpMethod = "POST"
        request.httpBody = postData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            defer {
                semaphore.signal()
            }
            guard let data = data else {
                errorObject = error
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let range = 400...599
                if range ~= httpResponse.statusCode {
                    let desc = "Invoke Connection call failed with the following status code " + String(httpResponse.statusCode)

                    let skyflowError = ErrorCodes.APIError(code: httpResponse.statusCode, message: desc).getErrorObject(contextOptions: self.contextOptions) as? SkyflowError
                    skyflowError?.setXML(xml: String(data: data, encoding: .utf8) ?? "")
                    errorObject = skyflowError
                    return
                }
            }
            var newActualResponse: String = ""
            do {
            newActualResponse = try SoapRequestHelpers.handleXMLResponse(responseXML: config.responseXML, actualResponse: String(data: data, encoding: .utf8)!, skyflow: self.skyflow, contextOptions: self.contextOptions)
            }
            catch {
                errorObject = error
                return
            }
            self.callback.onSuccess(newActualResponse)
          semaphore.signal()
        }

        task.resume()
        semaphore.wait()
        
        if(errorObject != nil) {
            self.callback.onFailure(errorObject)
        }
    }
}
