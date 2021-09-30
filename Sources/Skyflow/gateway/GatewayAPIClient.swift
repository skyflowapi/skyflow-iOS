import Foundation


class GatewayAPIClient {
    
    var callback: Callback
    
    internal init(callback: Callback) {
        self.callback = callback
    }
    
    internal func invokeGateway(config: GatewayConfig) throws{
        do {
            let url = try RequestHelpers.createRequestURL(baseURL: config.gatewayURL, pathParams: config.pathParams, queryParams: config.queryParams)
            let request = try RequestHelpers.createRequest(url: url, method: config.method, body: config.requestBody, headers: config.requestHeader)
        }
        catch {
            throw error
        }
//        if let url = URL(string: config.gatewayURL) {
//            var request = URLRequest(url: url)
//            request.httpMethod = "POST"
//
//            do {
//                let data = try JSONSerialization.data(withJSONObject: self.createRequestBody())
//                request.httpBody = data
//                request.httpMethod = config.method.rawValue
//            } catch let error {
//                self.callback.onFailure(error)
//                return
//            }
//
//            request.addValue("Bearer ", forHTTPHeaderField: "Authorization")
//
//            let session = URLSession(configuration: .default)
//
//            let task = session.dataTask(with: request) { data, response, error in
//                if(error != nil || response == nil){
//                    self.callback.onFailure(error!)
//                    return
//                }
//
//                if let httpResponse = response as? HTTPURLResponse{
//                    let range = 400...599
//                    if range ~= httpResponse.statusCode {
//                        var desc = "Insert call failed with the following status code" + String(httpResponse.statusCode)
//
//                        if let safeData = data{
//                            desc = String(decoding: safeData, as: UTF8.self)
//                        }
//
//                        self.callback.onFailure(NSError(domain:"", code:httpResponse.statusCode, userInfo:[NSLocalizedDescriptionKey: desc]))
//                        return
//                    }
//                }
//
//                if let safeData = data {
//                    let originalString = String(decoding: safeData, as: UTF8.self)
//                    let replacedString = originalString.replacingOccurrences(of: "\"*\":", with: "\"skyflow_id\":")
//                    let changedData = Data(replacedString.utf8)
//                    do {
//                        let jsonData = try JSONSerialization.jsonObject(with: changedData, options: .allowFragments) as! [String: Any]
//
//                        var responseEntries:[Any] = []
//
//                        let receivedResponseArray = (jsonData[keyPath: "responses"] as! [Any])
//
//                        let inputRecords = ["records"] as! [Any]
//
//                        let length = inputRecords.count
//                        for (index, _) in inputRecords.enumerated(){
//                            var tempEntry:[String:Any] = [:]
//                            tempEntry["table"] = (inputRecords[index] as! [String:Any])["table"]
//                            if true{
//                                let fieldsDict = (receivedResponseArray[length + index] as! [String:Any])["fields"] ?? nil
//                                if fieldsDict != nil {
//                                    let fieldsData = try JSONSerialization.data(withJSONObject: fieldsDict!)
//                                    let fieldsObj = try JSONSerialization.jsonObject(with: fieldsData, options: .allowFragments)
//                                    tempEntry["fields"] = self.buildFieldsDict(dict: fieldsObj as? [String: Any] ?? [:])
//                                }
//
//                            }
//                            else{
//                                tempEntry["skyflow_id"] = (((receivedResponseArray[index] as! [String:Any])["records"] as! [Any])[0] as! [String:Any])["skyflow_id"]
//                            }
//                            responseEntries.append(tempEntry)
//                        }
//
//                        self.callback.onSuccess(["records": responseEntries])
//
//                    } catch let error {
//                        self.callback.onFailure(error)
//                    }
//                }
//            }
//            task.resume()
//
//        }
        
    }
    
    internal func createRequestBody() -> [String: Any] {
        return ["request": "body"]
    }
    
    internal func buildFieldsDict(dict: [String: Any]) -> [String: Any]{
        var temp: [String: Any] = [:]
        for (key, val) in dict {
            if let v = val as? [String: Any]{
                temp[key] = buildFieldsDict(dict: v)
            }
            else{
                temp[key] = val
            }
        }
        return temp
    }
}
