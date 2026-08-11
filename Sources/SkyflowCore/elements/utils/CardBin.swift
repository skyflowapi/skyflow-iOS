/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation

extension Card {
    /// Get the BIN of a cardNumber,
    /// binCount is the number of characters that aren't masked
    internal class func getBIN(_ cardNumber: String, _ binCount: Int = 8) -> String {
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
