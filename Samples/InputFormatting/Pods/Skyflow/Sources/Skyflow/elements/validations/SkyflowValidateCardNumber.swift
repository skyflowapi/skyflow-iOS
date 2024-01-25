/*
 * Copyright (c) 2022 Skyflow
*/

/**
 Validate input in scope of Card Number, e.x.: [4111111111111111].
 */

import Foundation

internal struct SkyflowValidateCardNumber: ValidationRule {
    var error: String
    internal let regex: String

    public init(error: SkyflowValidationError, regex: String) {
        self.error = error
        self.regex = regex
    }

}

extension SkyflowValidateCardNumber: SkyflowInternalValidationProtocol {
    /// Validate the text (returns true if it is valid card number)
    func validate(_ text: String?) -> Bool {
        if text!.isEmpty {
            return true
        }

        let charactersArray = text?.components(separatedBy: [" ", "-"])
        let trimmedText = charactersArray?.joined(separator: "")
        if let cardNumber = trimmedText {

            let number = Int(cardNumber)
            if number == nil {
                return false
            }

            if !NSPredicate(format: "SELF MATCHES %@", self.regex).evaluate(with: text!) {
                return false
            }
            
            let cardType = CardType.forCardNumber(cardNumber: cardNumber)
            if cardType == .EMPTY || !cardType.instance.cardLengths.contains(cardNumber.count) {
                return false
            }
            

            return isLuhnValid(cardNumber: trimmedText!)
        }
        return false
    }

    /// Luhn Algorithm to validate card number
    private func isLuhnValid(cardNumber: String?) -> Bool {
        var sum = 0
        let digitStrings = cardNumber!.reversed().map { String($0) }

        for tuple in digitStrings.enumerated() {
            if let digit = Int(tuple.element) {
                let odd = tuple.offset % 2 == 1

                switch (odd, digit) {
                case (true, 9):
                    sum += 9
                case (true, 0...8):
                    sum += (digit * 2) % 9
                default:
                    sum += digit
                }
            } else {
                return false
            }
        }
        return sum % 10 == 0
    }
}
