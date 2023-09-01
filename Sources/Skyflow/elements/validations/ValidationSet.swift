/*
 * Copyright (c) 2022 Skyflow
*/

// Implementation of validation class

import Foundation

/// Set of validation rules.
public struct ValidationSet {
    internal var rules = [ValidationRule]()

    public init() { }

    /**
    Initializes the validation set with an array of validation rules.

    - Parameters:
        - rules: Validation rules to be included in the set.
    */
    public init(rules: [ValidationRule]) {
        self.rules = rules
    }

    /**
    Adds a validation rule to the set.

    - Parameters:
        - rule: Validation rule that is added to the set.
    */
    public mutating func add(rule: ValidationRule) {
             rules.append(rule)
    }
    
    internal mutating func append(_ ruleSet: ValidationSet) {
        for rule in ruleSet.rules {
            self.rules.append(rule)
        }
    }
}
