
import Foundation


public struct SkyflowValidateCard: SkyflowValidationProtocol {
    public func validate(input: String?) -> Bool {
        return true
    }
    

  /// Validation Error
  public var error: SkyflowValidationError
  
  /// Turn on/off validation of cards that are not defined in SDK - `CardBrand.unknown`
  public var validateUnknownCardBrand = false

  public init(error: SkyflowValidationError) {
    self.error = error
  }

  public init(error: SkyflowValidationError, validateUnknownCardBrand: Bool) {
    self.error = error
    self.validateUnknownCardBrand = validateUnknownCardBrand
  }
}

//extension SkyflowValidationRulePaymentCard: SkyflowValidator {
//
//  internal func validate(input: String?) -> Bool {
//
//    guard let input = input else {
//      return false
//    }
//
//    let cardBrand = SkyflowPaymentCards.detectCardBrandFromAvailableCards(input: input)
//
//    if cardBrand != .unknown {
//
//      /// validate known card brands
//
//      return validateCardNumberAsCardBrand(cardBrand, number: input)
//
//    } else if  cardBrand == .unknown && validateUnknownCardBrand {
//
//      /// validate .unknown brands if there are specific validation rules for undefined brands
//
//      return validateCardNumberAsUnknownBrand(number: input)
//    }
//
//    /// brand is not valid if it's type is .unknown and there are no specific validation rules for .unknown cards
//
//    return false
//  }
//
//  internal func validateCardNumberAsCardBrand(_ cardBrand: SkyflowPaymentCards.CardBrand, number: String) -> Bool {
//
//    /// Check if card brand in available card brands
//    guard let cardModel = SkyflowPaymentCards.getCardModelFromAvailableModels(brand: cardBrand) else {
//      return false
//    }
//
//    /// Validate defined brands
//    guard cardModel.cardNumberLengths.contains(number.count) else {
//      return false
//    }
//    return cardModel.checkSumAlgorithm?.validate(number) ?? true
//  }
//
//  internal func validateCardNumberAsUnknownBrand(number: String) -> Bool {
//    let unknownBrandModel = SkyflowPaymentCards.unknown
//    if !NSPredicate(format: "SELF MATCHES %@", unknownBrandModel.regex).evaluate(with: number) {
//        return false
//    }
//    if !(unknownBrandModel.cardNumberLengths.contains(number.count)) {
//      return false
//    }
//    return unknownBrandModel.checkSumAlgorithm?.validate(number) ?? true
//   }
//}
