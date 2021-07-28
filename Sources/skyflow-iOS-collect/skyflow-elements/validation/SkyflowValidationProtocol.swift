

import Foundation

public protocol SkyflowValidationProtocol {
  
    /// Validation Error
    var error: SkyflowValidationError { get }
    func validate(input: String?) -> Bool

}
