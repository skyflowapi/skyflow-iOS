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
        try verifyRequestAndResponseElements(contextOptions: contextOptions)

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
        try verifyRequestAndResponseElements(contextOptions: contextOptions)

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
    
    internal func getFormatRegexLabels() -> [String] {
        let result = [] as [String]
        
        // TODO: Traverse params and get LabelViews with formatRegex option
        
        return result
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
                try ConversionHelpers.checkElements(responseConfig, emptyTokenAllowed: true, contextOptions: contextOptions)
            } catch {
                throw error
            }
        }
    }
    
    internal func validate() throws -> ConnectionConfig {
        return self
    }
}
