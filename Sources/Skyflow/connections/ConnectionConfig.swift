import Foundation


// TODO: Implement getFormatRegexLabels and validate methods, add detokenizedValues to ConversionHelpers.convertOrFail() in convert()

public struct ConnectionConfig {
    var connectionURL: String
    var method: RequestMethod
    var pathParams: [String: Any]?
    var queryParams: [String: Any]?
    var requestBody: [String: Any]?
    var requestHeader: [String: String]?
    var responseBody: [String: Any]?

    public init(connectionURL: String, method: RequestMethod, pathParams: [String: Any]? = nil, queryParams: [String: Any]? = nil, requestBody: [String: Any]? = nil, requestHeader: [String: String]? = nil, responseBody: [String: Any]? = nil) {
        self.connectionURL = connectionURL
        self.method = method
        self.pathParams = pathParams
        self.queryParams = queryParams
        self.requestBody = requestBody
        self.requestHeader = requestHeader
        self.responseBody = responseBody
    }


    internal func convert(contextOptions: ContextOptions) throws -> ConnectionConfig {
        try validate(contextOptions: contextOptions)

        let convertedPathParams = try ConversionHelpers.convertOrFail(self.pathParams, false, false, contextOptions: contextOptions)
        let convertedQueryParams = try ConversionHelpers.convertOrFail(self.queryParams, false, contextOptions: contextOptions)
        let convertedRequestBody = try ConversionHelpers.convertOrFail(self.requestBody, contextOptions: contextOptions)
        let convertedRequestHeader = try ConversionHelpers.convertOrFail(self.requestHeader, contextOptions: contextOptions)  as! [String: String]?


        let stringedPathParams = ConversionHelpers.stringifyDict(convertedPathParams)
        let stringedQueryParams = ConversionHelpers.stringifyDict(convertedQueryParams)

        return ConnectionConfig(connectionURL: connectionURL,
                             method: method,
                             pathParams: stringedPathParams,
                             queryParams: stringedQueryParams,
                             requestBody: convertedRequestBody,
                             requestHeader: convertedRequestHeader,
                             responseBody: responseBody)
    }
    
    internal func convert(detokenizedValues: [String: String], contextOptions: ContextOptions) throws -> ConnectionConfig {
        try validate(contextOptions: contextOptions)

        let convertedPathParams = try ConversionHelpers.convertOrFail(self.pathParams, false, false, contextOptions: contextOptions, detokenizedValues: detokenizedValues)
        let convertedQueryParams = try ConversionHelpers.convertOrFail(self.queryParams, false, contextOptions: contextOptions, detokenizedValues: detokenizedValues)
        let convertedRequestBody = try ConversionHelpers.convertOrFail(self.requestBody, contextOptions: contextOptions, detokenizedValues: detokenizedValues)
        let convertedRequestHeader = try ConversionHelpers.convertOrFail(self.requestHeader, contextOptions: contextOptions, detokenizedValues: detokenizedValues)  as! [String: String]?


        let stringedPathParams = ConversionHelpers.stringifyDict(convertedPathParams)
        let stringedQueryParams = ConversionHelpers.stringifyDict(convertedQueryParams)

        return ConnectionConfig(connectionURL: connectionURL,
                             method: method,
                             pathParams: stringedPathParams,
                             queryParams: stringedQueryParams,
                             requestBody: convertedRequestBody,
                             requestHeader: convertedRequestHeader,
                             responseBody: responseBody)
    }

    
    internal func validate(contextOptions: ContextOptions) throws  {
        try ConversionHelpers.checkElements(self.pathParams ?? [:], contextOptions: contextOptions)
        try ConversionHelpers.checkElements(self.queryParams ?? [:], contextOptions: contextOptions)
        try ConversionHelpers.checkElements(self.requestHeader ?? [:], contextOptions: contextOptions)
        try ConversionHelpers.checkElements(self.requestBody ?? [:], contextOptions: contextOptions)
        try ConversionHelpers.checkElements(self.responseBody ?? [:], contextOptions: contextOptions)
    }
    
    internal func getLabelsToFormatInRequest(contextOptions: ContextOptions) throws -> [String: String] {
        try validate(contextOptions: contextOptions)
        
        var result = [:] as [String: String]
        result.merge(try ConversionHelpers.getElementTokensWithFormatRegex(self.requestBody ?? [:], contextOptions: contextOptions)) {
            (_, second) in second
        }
        result.merge(try ConversionHelpers.getElementTokensWithFormatRegex(self.pathParams ?? [:], contextOptions: contextOptions)) {
            (_, second) in second
        }
        result.merge(try ConversionHelpers.getElementTokensWithFormatRegex(self.queryParams ?? [:], contextOptions: contextOptions)) {
            (_, second) in second
        }
        result.merge(try ConversionHelpers.getElementTokensWithFormatRegex(self.requestHeader ?? [:], contextOptions: contextOptions)) {
            (_, second) in second
        }
        
        return result
    }
}
