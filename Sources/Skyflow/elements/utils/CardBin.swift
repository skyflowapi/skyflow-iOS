import Foundation

extension Card {
    /// Get the BIN of a cardNumber
    internal class func getBIN(_ cardNumber: String) -> String {
        let asis = 10 // Total number of characters to not mask
        var result = ""
    
        for (idx, char) in cardNumber.enumerated() {
            if idx >= asis {
                result += "X"
            } else {
                result += String(char)
            }
        }
    
        return result
    }
}
