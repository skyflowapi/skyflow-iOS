import Foundation


class GatewayAPIClient {
    var callback: Callback

    internal init(callback: Callback) {
        self.callback = callback
    }

    internal func invokeGateway(token: String, config: GatewayConfig) throws {
        let gatewayRequestGroup = DispatchGroup()

        var isSuccess = true
        var errorObject: Error!
        var convertedResponse: [String: Any] = [:]


        do {
            let url = try RequestHelpers.createRequestURL(baseURL: config.gatewayURL, pathParams: config.pathParams, queryParams: config.queryParams)
            var request = try RequestHelpers.createRequest(url: url, method: config.method, body: config.requestBody, headers: config.requestHeader)

            request.addValue(token, forHTTPHeaderField: "X-Skyflow-Authorization")

            let session = URLSession(configuration: .default)

            gatewayRequestGroup.enter()

            let task = session.dataTask(with: request) { data, response, error in
                defer {
                    gatewayRequestGroup.leave()
                }

                if error != nil {
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
                            convertedResponse = try RequestHelpers.parseActualResponseAndUpdateElements(response: responseData as! [String : Any], responseBody: config.responseBody ?? [:])
                        }
                        else if responseData is String, let httpResponse = response as? HTTPURLResponse {
                            isSuccess = false
                            errorObject = NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: responseData])
                            return
                        }
                        else {
                            isSuccess = false
                            errorObject = NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Error parsing response"])
                            return
                        }
                    } catch {
                        isSuccess = false
                        errorObject = NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: "Error parsing response \(error.localizedDescription)"])
                        return
                    }
                }
            }
            task.resume()

            gatewayRequestGroup.notify(queue: .main) {
                if isSuccess {
                    do {
                        let sanitizedResponse = try ConversionHelpers.removeEmptyValuesFrom(response: convertedResponse)

                        self.callback.onSuccess(sanitizedResponse)
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
