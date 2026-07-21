/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation

public struct SkyflowValidator {
    
    
  public static func validate(input: String?, rules: ValidationSet) -> SkyflowValidationError {
      let errors = rules.rules
        .filter { !($0 as! SkyflowInternalValidationProtocol).validate(input) }
          .map { $0.error }

      return errors.isEmpty ? SkyflowValidationError() : errors[0]
  }
 }
