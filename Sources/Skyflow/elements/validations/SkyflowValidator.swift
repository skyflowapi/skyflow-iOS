import Foundation

internal struct SkyflowValidator {

  internal static func validate(input: String?, rules: SkyflowValidationSet) -> [SkyflowValidationError] {

      let errors = rules.rules
          .filter { !$0.validate(text: input) }
          .map { $0.error }

      return errors.isEmpty ? [SkyflowValidationError]() : errors
  }
}
