/*
 * Copyright (c) 2022 Skyflow
*/

//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 25/12/21.
//

import Foundation

extension String {

    
    
    func getFirstRegexMatch(of regex: String, contextOptions: ContextOptions) throws -> String {
        guard let range = self.range(of: regex, options: .regularExpression) else { throw ErrorCodes.REGEX_MATCH_FAILED(value: regex).errorObject
        }
        return String(self[range])
    }
    
    
    func getFormattedText(with regex: String, replacementString: String? = nil, contextOptions: ContextOptions) -> String {
        if let replacementText = replacementString {
            return self.replacingOccurrences(of: regex, with: replacementText, options: .regularExpression)
        } else {
            do {
                return try self.getFirstRegexMatch(of: regex, contextOptions: contextOptions)
            } catch {
                Log.warn(message: .BEARER_TOKEN_RECEIVED, values:[regex], contextOptions: contextOptions)
            }
        }
        
        return self
    }
}
