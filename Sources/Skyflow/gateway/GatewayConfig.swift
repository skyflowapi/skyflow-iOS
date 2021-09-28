//
//  File.swift
//  
//
//  Created by Tejesh Reddy Allampati on 28/09/21.
//

import Foundation


struct GatewayConfig {
    var gatewayURL: String
    var method: String
    var pathParams: Any? = nil
    var queryParams: Any? = nil
    var requestBody: [String: Any]? = nil
    var requestHeader: Any? = nil
    var responseBody: Any? = nil
}
