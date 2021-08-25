
import Foundation


internal struct SkyflowValidationSet {
    
    internal var rules = [SkyflowValidationProtocol]()
    
    public init() { }
    
    public init(rules: [SkyflowValidationProtocol]) {
        
        self.rules = rules
    }
    
    /// Add validation rule
    public mutating func add(rule: SkyflowValidationProtocol) {
             rules.append(rule)
    }
}

