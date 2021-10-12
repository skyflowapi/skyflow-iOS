import Foundation


class GatewayAPIClient {
    var callback: Callback
    var contextOptions: ContextOptions
    
    internal init(callback: Callback, contextOptions: ContextOptions) {
        self.callback = callback
        self.contextOptions = contextOptions
    }
    
    internal func invokeGateway(token: String, config: GatewayConfig) throws {
        let gatewayRequestGroup = DispatchGroup()
        
        var isSuccess = true
        var errorObject: Error!
        var convertedResponse: [String: Any]? = nil
        var stringResponse: String? = nil
        
        do {
            let url = try RequestHelpers.createRequestURL(baseURL: config.gatewayURL, pathParams: config.pathParams, queryParams: config.queryParams, contextOptions: self.contextOptions)
            var request = try RequestHelpers.createRequest(url: url, method: config.method, body: config.requestBody, headers: config.requestHeader, contextOptions: self.contextOptions)
            
            request.addValue(token, forHTTPHeaderField: "X-Skyflow-Authorization")
            
            let session = URLSession(configuration: .default)
            
            gatewayRequestGroup.enter()
            
            let task = session.dataTask(with: request) { data, response, error in
                defer {
                    gatewayRequestGroup.leave()
                }
                
                if error != nil || response == nil {
                    isSuccess = false
                    errorObject = NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "invokeGateway - Error"])
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    let range = 400...599
                    if range ~= httpResponse.statusCode {
                        var desc = "Invoke Gateway call failed with the following status code" + String(httpResponse.statusCode)
                        
                        if let safeData = data {
                            desc = String(decoding: safeData, as: UTF8.self)
                        }
                        
                        isSuccess = false
                        errorObject = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: desc])
                        return
                    }
                }
                
                
                if let safeData = data {
                    do {
                        let responseData = try JSONSerialization.jsonObject(with: safeData, options: .allowFragments)
                        if(responseData is [String: Any]){
                            convertedResponse = try RequestHelpers.parseActualResponseAndUpdateElements(response: responseData as! [String : Any], responseBody: config.responseBody ?? [:], contextOptions: self.contextOptions)
                        }
                        else if responseData is String {
                            stringResponse = responseData as? String
                        }
                        else {
                            isSuccess = false
                            errorObject = NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Error parsing response"])
                            return
                        }
                    } catch {
                        isSuccess = false
                        errorObject = error
                        return
                    }
                }
            }
            task.resume()
            
            gatewayRequestGroup.notify(queue: .main) {
                if isSuccess {
                    do {
                        if convertedResponse != nil {
                            let sanitizedResponse = try ConversionHelpers.removeEmptyValuesFrom(response: convertedResponse!, contextOptions: self.contextOptions)
                            
                            self.callback.onSuccess(sanitizedResponse)
                        }
                        else if stringResponse != nil {
                            self.callback.onSuccess(stringResponse!)
                        }
                        else {
                            self.callback.onFailure(NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Error parsing response or no response"]))
                        }
                    } catch {
                        self.callback.onFailure(error)
                    }
                } else {
                    self.callback.onFailure(errorObject)
                }
            }
        } catch {
            throw error
        }
    }
}
