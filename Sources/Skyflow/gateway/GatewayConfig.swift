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
    
    
    internal func convert() throws -> GatewayConfig {
        do {
            let convertedPathParams = try ConversionHelpers.convertOrFail(self.pathParams, false)
            let convertedQueryParams = try ConversionHelpers.convertOrFail(self.queryParams, false)
            let convertedRequestBody = try ConversionHelpers.convertOrFail(self.requestBody)
            
            return GatewayConfig(gatewayURL: self.gatewayURL, method: self.method, pathParams: convertedPathParams, queryParams: convertedQueryParams, requestBody: convertedRequestBody, requestHeader: self.requestHeader, responseBody: self.responseBody)
        }
        catch {
            throw error
        }

    }
}
