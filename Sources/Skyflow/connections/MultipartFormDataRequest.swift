/*
 * Copyright (c) 2022 Skyflow
 */

import Foundation

struct MultipartFormDataRequest {
    private let boundary: String = UUID().uuidString
    private var httpBody = NSMutableData()
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    
    
    func addValues(json: [String: String]) {
        for (key, value) in json {
            self.addTextField(named: key, value: value)
        }
    }
    
    func addTextField(named name: String, value: String) {
        httpBody.append(textFormField(named: name, value: value))
    }
    
    private func textFormField(named name: String, value: String) -> String {
        var fieldString = "--\(boundary)\r\n"
        fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        fieldString += "\r\n"
        fieldString += "\(value)\r\n"
        
        return fieldString
    }
    
    
    func asURLRequest(with headers: [String: String]) -> URLRequest {
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        httpBody.append("--\(boundary)--")
        request.httpBody = httpBody as Data
        return request
    }
}

extension NSMutableData {
    func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}

