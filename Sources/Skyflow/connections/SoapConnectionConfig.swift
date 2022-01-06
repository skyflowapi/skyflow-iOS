//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 23/12/21.
//

import Foundation

public class SoapConnectionConfig {
    var connectionURL: String
    var httpHeaders: [String: String]
    var requestXML: String
    var responseXML: String
    
    public init(connectionURL: String, httpHeaders: [String: String] = [:], requestXML: String, responseXML: String = ""){
        self.connectionURL = connectionURL
        self.httpHeaders = httpHeaders
        self.requestXML = requestXML
        self.responseXML = responseXML
    }
}
