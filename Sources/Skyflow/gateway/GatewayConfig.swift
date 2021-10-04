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


    public func convert() throws -> GatewayConfig {
        do {
            try verifyRequestAndResponseElements()

            let convertedPathParams = try ConversionHelpers.convertOrFail(self.pathParams, false, false)
            let convertedQueryParams = try ConversionHelpers.convertOrFail(self.queryParams, false)
            let convertedRequestBody = try ConversionHelpers.convertOrFail(self.requestBody)
            let convertedRequestHeader = try ConversionHelpers.convertOrFail(self.requestHeader)  as! [String: String]?

            return GatewayConfig(gatewayURL: gatewayURL,
                                 method: method,
                                 pathParams: convertedPathParams,
                                 queryParams: convertedQueryParams,
                                 requestBody: convertedRequestBody,
                                 requestHeader: convertedRequestHeader,
                                 responseBody: responseBody)
        } catch {
            throw error
        }
    }

    public func verifyRequestAndResponseElements() throws {
        if let requestConfig = self.requestBody {
            do {
                try ConversionHelpers.checkElements(requestConfig, true)
            } catch {
                throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription + " in request body"])
            }
        }

        if let responseConfig = self.responseBody {
            do {
                try ConversionHelpers.checkElements(responseConfig)
            } catch {
                throw NSError(domain: "", code: 400, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription + " in response body"])
            }
        }
    }
}