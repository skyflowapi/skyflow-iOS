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
    var pathParams: [String: Any]?
    var queryParams: [String: Any]?
    var requestBody: [String: Any]?
    var requestHeader: [String: String]?
    var responseBody: [String: Any]?

    public init(gatewayURL: String, method: RequestMethod, pathParams: [String: Any]? = nil, queryParams: [String: Any]? = nil, requestBody: [String: Any]? = nil, requestHeader: [String: String]? = nil, responseBody: [String: Any]? = nil) {
        self.gatewayURL = gatewayURL
        self.method = method
        self.pathParams = pathParams
        self.queryParams = queryParams
        self.requestBody = requestBody
        self.requestHeader = requestHeader
        self.responseBody = responseBody
    }


    internal func convert(contextOptions: ContextOptions) throws -> GatewayConfig {
        try verifyRequestAndResponseElements(contextOptions: contextOptions)

        let convertedPathParams = try ConversionHelpers.convertOrFail(self.pathParams, false, false, contextOptions: contextOptions)
        let convertedQueryParams = try ConversionHelpers.convertOrFail(self.queryParams, false, contextOptions: contextOptions)
        let convertedRequestBody = try ConversionHelpers.convertOrFail(self.requestBody, contextOptions: contextOptions)
        let convertedRequestHeader = try ConversionHelpers.convertOrFail(self.requestHeader, contextOptions: contextOptions)  as! [String: String]?

        return GatewayConfig(gatewayURL: gatewayURL,
                             method: method,
                             pathParams: convertedPathParams,
                             queryParams: convertedQueryParams,
                             requestBody: convertedRequestBody,
                             requestHeader: convertedRequestHeader,
                             responseBody: responseBody)
    }

    internal func verifyRequestAndResponseElements(contextOptions: ContextOptions) throws {
        if let requestConfig = self.requestBody {
            do {
                try ConversionHelpers.checkElements(requestConfig, true, contextOptions: contextOptions)
            } catch {
                throw error
            }
        }

        if let responseConfig = self.responseBody {
            do {
                try ConversionHelpers.checkElements(responseConfig, contextOptions: contextOptions)
            } catch {
                throw error
            }
        }
    }
}
