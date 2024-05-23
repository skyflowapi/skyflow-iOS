/*
 * Copyright (c) 2022 Skyflow
*/

// Implementation of Callback used in API for revealing data by get method

import Foundation

class GetAPICallback: Callback {
    var apiClient: APIClient
    var callback: Callback
    var connectionUrl: String
    var records: [GetRecord]
    var contextOptions: ContextOptions
    var getOptions: GetOptions


    internal init(callback: Callback, apiClient: APIClient, connectionUrl: String,
                  records: [GetRecord],getOptions: GetOptions, contextOptions: ContextOptions) {
        self.apiClient = apiClient
        self.callback = callback
        self.connectionUrl = connectionUrl
        self.records = records
        self.getOptions = getOptions
        self.contextOptions = contextOptions
    }

    internal func onSuccess(_ token: Any) {
        let getRequestGroup = DispatchGroup()
        var outputArray: [[String: Any]] = []
        var errorArray: [[String: Any]] = []
        var isSuccess: Bool?
        var errorObject: Error!

        if URL(string: (connectionUrl + "/")) == nil {
            self.callRevealOnFailure(callback: callback, errorObject: ErrorCodes.INVALID_URL().getErrorObject(contextOptions: self.contextOptions))
            return
        }

        for record in records {
            let urlComponents = getUrlComponents(record: record, getOptions: getOptions)

            getRequestGroup.enter()

            if urlComponents?.url?.absoluteURL == nil {
                var errorEntryDict: [String: Any] = [
                    "ids": record.ids
                ]
                let errorDict: [String: Any] = [
                    "code": 400,
                    "description": "Table name or id is invalid"
                ]
                errorEntryDict["error"] = errorDict
                errorArray.append(errorEntryDict)
                continue
            }
            let (request, session) = getRequestSession(urlComponents: urlComponents)
                        
            let task = session.dataTask(with: request) { data, response, error in
                defer {
                    getRequestGroup.leave()
                }
                
                do {
                    var (resultArray, errorResponse) = try self.processURLResponse(record: record, data: data, response: response, error: error)
                    outputArray.append(contentsOf: resultArray ?? [])
                    if errorResponse != nil {
                        errorArray.append(errorResponse!)
                    }
                } catch {
                    isSuccess = false
                    errorObject = error
                }
            }
                
            task.resume()
        }
        getRequestGroup.notify(queue: .main) {
            self.handleCallbacks(outputArray: outputArray, errorArray: errorArray, isSuccess: isSuccess, errorObject: errorObject)
        }
    }
    internal func onFailure(_ error: Any) {
        if error is Error {
            callRevealOnFailure(callback: self.callback, errorObject: error as! Error)
        } else {
            self.callback.onFailure(error)
        }
    }

    internal func buildFieldsDict(dict: [String: Any]) -> [String: Any] {
        var temp: [String: Any] = [:]
        for (key, val) in dict {
                if let v = val as? [String: Any] {
                    temp[key] = buildFieldsDict(dict: v)
                } else {
                    temp[key] = val
                }
        }
        return temp
    }

    private func callRevealOnFailure(callback: Callback, errorObject: Error) {
        let result = ["errors": [["error" : errorObject]]]
        callback.onFailure(result)
    }
    
    internal func getRequestSession(urlComponents: URLComponents?) -> (URLRequest, URLSession) {
        var jsonString = ""

        do {
           let deviceDetails = FetchMetrices().getMetrices()
           let jsonData = try JSONSerialization.data(withJSONObject: deviceDetails, options: [])
           jsonString = String(data: jsonData, encoding: .utf8) ?? ""
        } catch {
            jsonString = ""
        }
        var request = URLRequest(url: (urlComponents?.url!.absoluteURL)!)
        request.httpMethod = "GET"
        request.setValue("application/json; utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(("Bearer " + self.apiClient.token), forHTTPHeaderField: "Authorization")
        request.setValue(jsonString, forHTTPHeaderField: "sky-metadata")

        return (request, URLSession(configuration: .default))
    }
    
    internal func getUrlComponents(record: GetRecord, getOptions: GetOptions) -> URLComponents? {
        var urlComponents = URLComponents(string: (connectionUrl + "/" + record.table))

        urlComponents?.queryItems = []
        if (record.ids != nil){
            for id in record.ids!{
                urlComponents?.queryItems?.append(URLQueryItem(name: "skyflow_ids", value: id))
            }
        } else if record.columnValues != nil && record.columnName != nil{
            if let array = record.columnValues {
                for (index, value) in array.enumerated() {
                    if index == 0 {
                        urlComponents?.queryItems?.append(URLQueryItem(name: "column_name", value: record.columnName))
                    }
                    urlComponents?.queryItems?.append(URLQueryItem(name: "column_values", value: value))
                }
            }
        }
        if(record.redaction != nil && getOptions.tokens == false){
            urlComponents?.queryItems?.append(URLQueryItem(name: "redaction", value: record.redaction))
        } else {
            urlComponents?.queryItems?.append(URLQueryItem(name: "tokenization", value: String(getOptions.tokens)))
        }
        return urlComponents
    }

    func constructApiError(record: GetRecord, _ safeData: Data, _ httpResponse: HTTPURLResponse) throws -> [String: Any] {
        let desc = try JSONSerialization.jsonObject(with: safeData, options: .allowFragments) as! [String: Any]
        var description = "get call failed with the following status code" + String(httpResponse.statusCode)

        var errorEntryDict: [String: Any] = [:]
        if record.ids != nil {
            errorEntryDict = [
                "ids": record.ids!
            ]
        } else if record.columnValues != nil {
            errorEntryDict = [
                "columnValues": record.columnValues as Any,
                "columnName": record.columnName as String?
            ]
        }
        
        if let error = desc["error"] as? [String: Any], let message = error["message"] as? String {
            description = message
            
            if let requestId = httpResponse.allHeaderFields["x-request-id"] {
                description += " - request-id: \(requestId)"
            }
            let errorDict: NSError = ErrorCodes.APIError(code: httpResponse.statusCode, message: description).getErrorObject(contextOptions: self.contextOptions)
            errorEntryDict["error"] = errorDict
        }

        return errorEntryDict
    }
    
    func processResponse(record: GetRecord, _ safeData: Data) throws -> [[String: Any]] {
        var outputArray = [[String: Any]]()
        let originalString = String(decoding: safeData, as: UTF8.self)
        let replacedString = originalString.replacingOccurrences(of: "\"skyflow_id\":", with: "\"id\":")
        let changedData = Data(replacedString.utf8)
        let jsonData = try JSONSerialization.jsonObject(with: changedData, options: .allowFragments) as! [String: Any]
        if let jsonDataArray = jsonData["records"] as? [[String: Any]] {
            for entry in jsonDataArray {
                var entryDict = self.buildFieldsDict(dict: entry)
                entryDict["table"] = record.table
                entryDict.removeValue(forKey: "tokens")
                outputArray.append(entryDict)
            }
        }
        return outputArray
    }
    
    func constructGetRecords(_ outputArray: [[String: Any]], _ errorArray: [[String: Any]]) -> [String: Any]{
        var records: [String: Any] = [:]
        if outputArray.count != 0 {
            records["records"] = outputArray
        }
        if errorArray.count != 0 {
            records["errors"] = errorArray
        }
        return records
    }
    
    func handleCallbacks(outputArray: [[String: Any]], errorArray: [[String: Any]], isSuccess: Bool?, errorObject: Error?) {
        let records = self.constructGetRecords(outputArray, errorArray)
        if isSuccess ?? true {
            if errorArray.isEmpty {
                self.callback.onSuccess(records)
            } else {
                self.callback.onFailure(records)
            }
        } else {
            self.callRevealOnFailure(callback: self.callback, errorObject: errorObject!)
        }
    }
    
    func processURLResponse(record: GetRecord, data: Data?, response: URLResponse?, error: Error?) throws -> ([[String: Any]]?, [String: Any]?) {
        if error != nil || response == nil {
            throw error!
        }
        if let httpResponse = response as? HTTPURLResponse {
            let range = 400...599
            if range ~= httpResponse.statusCode {

                if let safeData = data {
                    let errorEntry = try self.constructApiError(record: record, safeData, httpResponse)
                    return (nil, errorEntry)
                }
                return (nil, nil)
            }
        }

        if let safeData = data {
            let resultArray = try self.processResponse(record: record, safeData)

            return (resultArray, nil)
        }
        
        return (nil, nil)
    }
}
