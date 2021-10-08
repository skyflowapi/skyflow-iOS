//
//  File.swift
//  
//
//  Created by Santhosh Kamal Murthy Yennam on 10/08/21.
//

import Foundation

class RevealApiCallback: Callback {
    var apiClient: APIClient
    var callback: Callback
    var connectionUrl: String
    var records: [RevealRequestRecord]


    internal init(callback: Callback, apiClient: APIClient, connectionUrl: String,
                  records: [RevealRequestRecord]) {
        self.apiClient = apiClient
        self.callback = callback
        self.connectionUrl = connectionUrl
        self.records = records
    }

    internal func onSuccess(_ token: Any) {
        var list_success: [RevealSuccessRecord] = []
        var list_error: [RevealErrorRecord] = []
        let revealRequestGroup = DispatchGroup()

        var isSuccess = true
        var errorObject: Error!
        var errorCode: ErrorCodes?

        if URL(string: (connectionUrl + "/tokens")) == nil {
            errorCode = .INVALID_URL()
            self.callback.onFailure(errorCode!.errorObject)
            return
        }

        for record in records {
            var urlComponents = URLComponents(string: (connectionUrl + "/tokens"))

            urlComponents?.queryItems = []

            urlComponents?.queryItems?.append(URLQueryItem(name: "redaction", value: record.redaction))

            urlComponents?.queryItems?.append(URLQueryItem(name: "token_ids", value: record.token))


            if urlComponents?.url?.absoluteURL == nil {
                var errorEntryDict: [String: Any] = [
                    "token": record.token
                ]
                let errorDict: [String: Any] = [
                    "code": 400,
                    "description": "Token is invalid"
                ]
                errorEntryDict["error"] = errorDict
//                errorArray.append(errorEntryDict)
                continue
            }

//            let url = URL(string: (connectionUrl+"/tokens?token_ids="+record.token+"&redaction="+record.redaction))
            revealRequestGroup.enter()
            var request = URLRequest(url: (urlComponents?.url!.absoluteURL)!)
            request.httpMethod = "GET"
            request.addValue("application/json; utf-8", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue(("Bearer " + self.apiClient.token), forHTTPHeaderField: "Authorization")
            let session = URLSession(configuration: .default)

            let task = session.dataTask(with: request) { data, response, error in
                defer {
                    revealRequestGroup.leave()
                }
                if error != nil || response == nil {
                    isSuccess = false
                    errorObject = error!
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    let range = 400...599
                    if range ~= httpResponse.statusCode {
                        var description = "Reveal call failed with the following status code" + String(httpResponse.statusCode)

                        if let safeData = data {
                            do {
                                let desc = try JSONSerialization.jsonObject(with: safeData, options: .allowFragments) as! [String: Any]
                                let error = desc["error"] as! [String: Any]
                                description = error["message"] as! String
                            } catch let error {
                                isSuccess = false
                                errorObject = error
                            }
                        }
                        var error: [String: String] = [:]
                        error["code"] = String(httpResponse.statusCode)
                        error["description"] = description
                        let errorRecord = RevealErrorRecord(id: record.token, error: error )
                        list_error.append(errorRecord)
                        return
                    }
                }

                if let safeData = data {
                    do {
                        let jsonData = try JSONSerialization.jsonObject(with: safeData, options: .allowFragments) as! [String: Any]
                        let receivedResponseArray: [Any] = (jsonData[keyPath: "records"] as! [Any])
                        let records: [String: Any] = receivedResponseArray[0] as! [String: Any]
                        list_success.append(RevealSuccessRecord(token_id: records["token_id"] as! String, fields: records["fields"] as! [String: String]))
                    } catch let error {
                        isSuccess = false
                        errorObject = error
                    }
                }
            }

            task.resume()
        }

        revealRequestGroup.notify(queue: .main) {
            var records: [Any] = []
            for record in list_success {
                var entry: [String: Any] = [:]
                entry["token"] = record.token_id
                var fields: [String: Any] = [:]
                for field in record.fields {
                    fields[field.key] = field.value
                }
                entry["fields"] = fields
                records.append(entry)
            }
            var errors: [Any] = []
            for record in list_error {
                var entry: [String: Any] = [:]
                entry["token"] = record.id
                var temp: [String: Any] = [:]
                for field in record.error {
                    temp[field.key] = field.value
                }
                entry["error"] = temp
                errors.append(entry)
            }
            var modifiedResponse: [String: Any] = [:]
            if records.count != 0 {
            modifiedResponse["records"] = records
            }
            if errors.count != 0 {
            modifiedResponse["errors"] = errors
            }

            if isSuccess {
                self.callback.onSuccess(modifiedResponse)
            } else {
                self.callback.onFailure(errorObject)
            }
        }
    }
    internal func onFailure(_ error: Error) {
        self.callback.onFailure(error)
    }
}
