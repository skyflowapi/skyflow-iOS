//
//  ElementValueMatch.swift
//  
//
//  Created by Akhil Anil Mangala on 22/11/21.
//

import Foundation

/**
 Validate input if it matches with that of another element
 */
public struct ElementValueMatch: ValidationRule {
    /// element to be matched against
    private let element: TextField
    
    /// Validation Error
    public let error: SkyflowValidationError
    
    public init(element: TextField, error: SkyflowValidationError="Length match failed") {
        self.element = element
        self.error = error
    }
}

extension ElementValueMatch: SkyflowInternalValidationProtocol {
    /// validate length of text
    public func validate(_ text: String?) -> Bool {
        guard text != nil else {
            return false
        }
        if text!.isEmpty {
            return true
        }
        return text! == (element as! TextField).actualValue
    }
}
