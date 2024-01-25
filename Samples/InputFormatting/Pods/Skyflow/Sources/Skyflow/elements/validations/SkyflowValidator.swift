/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation

internal struct SkyflowValidator {
    
    
  internal static func validate(input: String?, rules: ValidationSet) -> SkyflowValidationError {
      let errors = rules.rules
        .filter { !($0 as! SkyflowInternalValidationProtocol).validate(input) }
          .map { $0.error }

      return errors.isEmpty ? SkyflowValidationError() : errors[0]
  }
 }
