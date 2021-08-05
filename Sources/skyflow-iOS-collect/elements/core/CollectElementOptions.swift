
import Foundation
#if os(iOS)
import UIKit
#endif

/// A class responsible for configuration SkyflowTextField.
public class CollectElementOptions {
    
  
    /// Type of field congfiguration. Default is `FieldType.none`.
    public var type: FieldType = .none
    
    /// Name that will be associated with `SkyflowTextField` and used as a JSON key on send request with textfield data to your organozation vault.
    public let fieldName: String
    
    /// Set if `SkyflowTextField` is required to be non-empty and non-nil on send request. Default is `false`.
    public var isRequired: Bool = false
    
    
    /// Input data visual format pattern. If not applied, will be  set by default depending on field `type`.
    public var formatPattern: String?
    
    /// Preferred UIKeyboardType for `SkyflowTextField`.  If not applied, will be set by default depending on field `type` parameter.
    public var keyboardType: UIKeyboardType?
    
    ///Preferred UIReturnKeyType for `SkyflowTextField`.
    public var returnKeyType: UIReturnKeyType?
    
    /// Preferred UIKeyboardAppearance for textfield. By default is `UIKeyboardAppearance.default`.
    public var keyboardAppearance: UIKeyboardAppearance?
  
    /// Validation rules for field input. Defines `State.isValide` result.
    public var validationRules: SkyflowValidationSet?
               
    public init(fieldName: String)
    {
        self.fieldName = fieldName
    }
}
