
import Foundation

/**
Validate input in the scope of matching supported cards.
*/
internal struct SkyflowValidateCardNumber: SkyflowValidationProtocol {
    
    
   
    /// Validation Error
    public let error: SkyflowValidationError

    public init(error: SkyflowValidationError) {
        self.error = error
    }
    
    /// validate the text (returns true if it is valid Card Number)
   public  func validate(text: String?) -> Bool {

        if (text!.isEmpty) {
            return true
        }
        let number = Int(text!)
        if number == nil {
            return false
        }
    
        let card = CardType.forCardNumber(cardNumber: text!)
        let numberLength = text!.count
        if (numberLength < card.minCardLength || numberLength > card.maxCardLength) {
            return false
        } else if (!NSPredicate(format: "SELF MATCHES %@", card.regex).evaluate(with: text!)) {
            return false
        }
         return isLuhnValid(cardNumber: text!)
       
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


