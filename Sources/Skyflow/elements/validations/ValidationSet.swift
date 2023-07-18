/*
 * Copyright (c) 2022 Skyflow
*/

// Implementation of validation class

import Foundation

/// This is the description ValidationSet
public struct ValidationSet {
    internal var rules = [ValidationRule]()

    public init() { }

    /**
    This is the description for init method.

    - Parameters:
        - rules: This is the description for rules parameter.
    */
    public init(rules: [ValidationRule]) {
        self.rules = rules
    }

    /**
    Add validation rule.

    - Parameters:
        - rule: This is the description for rule parameter.
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
