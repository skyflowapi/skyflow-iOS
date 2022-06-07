import Foundation

extension Card {
    /// Get the BIN of a cardNumber
    internal class func getBIN(_ cardNumber: String) -> String {
        let binCount = 8 // Total number of characters to include in bin
        var result = ""
        var numbers = 0
    
        for char in cardNumber {
            if numbers >= binCount, char.isNumber {
                result += "X"
            } else {
                if char.isNumber {
                    numbers += 1
                }
                result += String(char)
            }
        }
    
        return result
    }
}
