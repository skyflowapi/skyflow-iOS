

import Foundation

internal protocol SkyflowValidationProtocol {
  
    /// Validation Error
    var error: SkyflowValidationError { get }
    func validate(text: String?) -> Bool

}