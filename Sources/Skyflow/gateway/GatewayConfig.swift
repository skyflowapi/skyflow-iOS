//
//  File.swift
//  
//
//  Created by Tejesh Reddy Allampati on 28/09/21.
//

import Foundation


public struct GatewayConfig {
    var gatewayURL: String
    var method: RequestMethod
    var pathParams: [String: Any]? = nil
    var queryParams: [String: Any]? = nil
    var requestBody: [String: Any]? = nil
    var requestHeader: [String: String]? = nil
    var responseBody: [String: Any]? = nil
    
    public init(gatewayURL: String, method: RequestMethod, pathParams: [String: Any]? = nil, queryParams: [String: Any]? = nil, requestBody: [String: Any]? = nil, requestHeader: [String: String]? = nil, responseBody: [String: Any]? = nil) {
        self.gatewayURL = gatewayURL
        self.method = method
        self.pathParams = pathParams
        self.queryParams = queryParams
        self.requestBody = requestBody
        self.requestHeader = requestHeader
        self.responseBody = responseBody
    }
    
    
    public func convert() throws -> GatewayConfig {
        do {
            let convertedPathParams = try ConversionHelpers.convertOrFail(self.pathParams, false, false)
            let convertedQueryParams = try ConversionHelpers.convertOrFail(self.queryParams, false)
            let convertedRequestBody = try ConversionHelpers.convertOrFail(self.requestBody)
            let convertedRequestHeader = try ConversionHelpers.convertOrFail(self.requestHeader)
            
            return GatewayConfig(gatewayURL: self.gatewayURL, method: self.method, pathParams: convertedPathParams, queryParams: convertedQueryParams, requestBody: convertedRequestBody, requestHeader: convertedRequestHeader as! [String: String]?, responseBody: self.responseBody)
        }
        catch {
            throw error
        }

    }
}
