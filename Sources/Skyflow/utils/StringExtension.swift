//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 25/12/21.
//

import Foundation

extension String {

    func replacingFirstOccurrence(of target: String, with replacement: String) -> String {
        guard let range = self.range(of: target) else { return self }
        return self.replacingCharacters(in: range, with: replacement)
    }
    
    func getFirstRegexMatch(of regex: String, contextOptions: ContextOptions) throws -> String {
        guard let range = self.range(of: regex, options: .regularExpression) else { throw ErrorCodes.REGEX_MATCH_FAILED(value: regex).getErrorObject(contextOptions: contextOptions)}
        return String(self[range])
    }
}
