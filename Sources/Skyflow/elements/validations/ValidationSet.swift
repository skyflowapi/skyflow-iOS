import Foundation


public struct ValidationSet {
    internal var rules = [ValidationRule]()

    public init() { }

    public init(rules: [ValidationRule]) {
        self.rules = rules
    }

    /// Add validation rule
    public mutating func add(rule: ValidationRule) {
             rules.append(rule)
    }
    
    internal mutating func append(_ ruleSet: ValidationSet) {
        for rule in ruleSet.rules {
            self.rules.append(rule)
        }
    }
}