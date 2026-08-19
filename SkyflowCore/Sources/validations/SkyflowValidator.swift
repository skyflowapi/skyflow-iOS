/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation

internal struct SkyflowValidator {
    
    
  internal static func validate(input: String?, rules: ValidationSet) -> SkyflowValidationError {
      // ValidationRule (public) only requires `error` - a customer-authored rule that doesn't
      // also conform to the internal validation protocol has no way to be evaluated here, so it's
      // treated as passing rather than crashing the force-cast.
      let errors = rules.rules
        .filter { ($0 as? SkyflowInternalValidationProtocol)?.validate(input) == false }
          .map { $0.error }

      return errors.isEmpty ? SkyflowValidationError() : errors[0]
  }
 }
