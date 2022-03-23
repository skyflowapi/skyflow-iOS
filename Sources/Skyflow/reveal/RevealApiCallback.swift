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
    var contextOptions: ContextOptions


    internal init(callback: Callback, apiClient: APIClient, connectionUrl: String,
                  records: [RevealRequestRecord], contextOptions: ContextOptions) {
        self.apiClient = apiClient
        self.callback = callback
        self.connectionUrl = connectionUrl
        self.records = records
        self.contextOptions = contextOptions
    }

    internal func onSuccess(_ token: Any) {
        var list_success: [RevealSuccessRecord] = []
        var list_error: [RevealErrorRecord] = []
        let revealRequestGroup = DispatchGroup()

        var isSuccess = true
        var errorObject: Error!
        var errorCode: ErrorCodes?


        // Check before pushing
        if URL(string: (connectionUrl + "/detokenize")) == nil {
            errorCode = .INVALID_URL()
            self.callRevealOnFailure(callback: self.callback, errorObject: errorCode!.getErrorObject(contextOptions: self.contextOptions))
            return
        }

        for record in records {
            let url = URL(string: (connectionUrl + "/detokenize"))
            revealRequestGroup.enter()
            var request = URLRequest(url: url!)
            request.httpMethod = "POST"
            request.setValue("application/json; utf-8", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue(("Bearer " + self.apiClient.token), forHTTPHeaderField: "Authorization")

            do {
                let bodyObject: [String: Any] =
                [
                    "detokenizationParameters": [
                        [
                            "token": record.token
                        ]
                    ]
                ]
                let data = try JSONSerialization.data(withJSONObject: bodyObject)
                request.httpBody = data
            } catch let error {
                self.callback.onFailure(error)
                return
            }


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
                                if let requestId = httpResponse.allHeaderFields["x-request-id"] {
                                    description += " - request-id: \(requestId)"
                                }
                            } catch let error {
                                isSuccess = false
                                errorObject = error
                            }
                        }
                        let error: NSError = ErrorCodes.APIError(code: httpResponse.statusCode, message: description).getErrorObject(contextOptions: self.contextOptions)
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
                        list_success.append(RevealSuccessRecord(token_id: records["token"] as! String, value: records["value"] as! String))
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
                entry["value"] = record.value
                records.append(entry)
            }
            var errors: [Any] = []
            for record in list_error {
                var entry: [String: Any] = [:]
                entry["token"] = record.id
                entry["error"] = record.error
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
                if errors.isEmpty {
                    self.callback.onSuccess(modifiedResponse)
                } else {
                    self.callback.onFailure(modifiedResponse)
                }
            } else {
                self.callRevealOnFailure(callback: self.callback, errorObject: errorObject)
            }
        }
    }
    internal func onFailure(_ error: Any) {
        if error is Error {
            callRevealOnFailure(callback: self.callback, errorObject: error as! Error)
        } else {
            self.callback.onFailure(error)
        }
    }

    private func callRevealOnFailure(callback: Callback, errorObject: Error) {
        let result = ["errors": [["error": errorObject]]]
        callback.onFailure(result)
    }
}
