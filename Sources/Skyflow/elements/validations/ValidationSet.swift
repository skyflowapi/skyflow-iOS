import Foundation


public struct ValidationSet {
    internal var rules = [SkyflowValidationProtocol]()

    public init() { }

    public init(rules: [SkyflowValidationProtocol]) {
        self.rules = rules
    }

    /// Add validation rule
    public mutating func add(rule: SkyflowValidationProtocol) {
             rules.append(rule)
    }
    
    internal mutating func append(_ ruleSet: ValidationSet) {
        for rule in ruleSet.rules {
            self.rules.append(rule)
        }
    }
}
