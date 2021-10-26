//
//  File.swift
//  
//
//  Created by Akhil Anil Mangala on 25/10/21.
//

import Foundation

internal class Card {
        var defaultName: String
        var regex: String
        var minCardLength: Int
        var maxCardLength: Int
        var formatPattern: String
        var securityCodeLength: Int
        var securityCodeName: String
        var imageName: String
        public required init( defaultName: String, regex: String, minCardLength: Int, maxCardLength: Int, formatPattern: String, securityCodeLength: Int, securityCodeName: String, imageName: String) {
            self.defaultName = defaultName
            self.regex = regex
            self.minCardLength = minCardLength
            self.maxCardLength = maxCardLength
            self.formatPattern = formatPattern
            self.securityCodeLength = securityCodeLength
            self.securityCodeName = securityCodeName
            self.imageName = imageName
        }
}

/// Default Cards and their FormatPatterns and validationrules.
public enum  CardType: CaseIterable {
    case VISA
    case MASTERCARD
    case DISCOVER
    case AMEX
    case DINERS_CLUB
    case JCB
    case MAESTRO
    case UNIONPAY
    case HIPERCARD
    case UNKNOWN
    case EMPTY

    var instance: Card {
        switch self {
        case .VISA : return Card(
            defaultName: "Visa", regex: "^4\\d*", minCardLength: 13, maxCardLength: 19, formatPattern: "#### #### #### #### ###", securityCodeLength: 3, securityCodeName: SecurityCode.cvv.rawValue, imageName: "Visa-Card")

        case .MASTERCARD: return Card(
            defaultName: "MasterCard", regex: "^(5[1-5]|222[1-9]|22[3-9]|2[3-6]|27[0-1]|2720)\\d*",
            minCardLength: 16, maxCardLength: 16, formatPattern: "#### #### #### ####",
            securityCodeLength: 3, securityCodeName: SecurityCode.cvc.rawValue, imageName: "Mastercard-Card")

        case .DISCOVER : return Card(
            defaultName: "Discover", regex: "^(6011|65|64[4-9]|622)\\d*",
            minCardLength: 16, maxCardLength: 16, formatPattern: "#### #### #### ####",
            securityCodeLength: 3, securityCodeName: SecurityCode.cid.rawValue, imageName: "Discover-Card")

        case .AMEX: return Card(
            defaultName: "Amex", regex: "^3[47]\\d*",
            minCardLength: 15, maxCardLength: 15, formatPattern: "#### ###### #####",
            securityCodeLength: 4, securityCodeName: SecurityCode.cid.rawValue, imageName: "Amex-Card")

        case .DINERS_CLUB: return Card(
            defaultName: "Diners Club", regex: "^(36|38|30[0-5])\\d*",
            minCardLength: 14, maxCardLength: 16, formatPattern: "#### ###### #####",
            securityCodeLength: 3, securityCodeName: SecurityCode.cvv.rawValue, imageName: "Diners-Card")

        case .JCB: return Card(
            defaultName: "JCB", regex: "^35\\d*",
            minCardLength: 16, maxCardLength: 19, formatPattern: "#### #### #### #### ###",
            securityCodeLength: 3, securityCodeName: SecurityCode.cvv.rawValue, imageName: "JCB-Card")

        case .MAESTRO: return Card(
            defaultName: "Maestro", regex: "^(5018|5020|5038|5043|5[6-9]|6020|6304|6703|6759|676[1-3])\\d*",
            minCardLength: 12, maxCardLength: 19, formatPattern: "#### #### #### #### ###",
            securityCodeLength: 3, securityCodeName: SecurityCode.cvc.rawValue, imageName: "Maestro-Card")

        case .UNIONPAY: return Card(
            defaultName: "UnionPay", regex: "^62\\d*",
            minCardLength: 16, maxCardLength: 19, formatPattern: "#### #### #### #### ###",
            securityCodeLength: 3, securityCodeName: SecurityCode.cvn.rawValue, imageName: "Unionpay-Card")

        case .HIPERCARD: return Card(
            defaultName: "HiperCard", regex: "^606282\\d*",
            minCardLength: 14, maxCardLength: 19, formatPattern: "#### #### #### #### ###",
            securityCodeLength: 3, securityCodeName: SecurityCode.cvc.rawValue, imageName: "Hipercard-Card")
        case .UNKNOWN: return Card(
            defaultName: "Unknown", regex: "\\d+",
            minCardLength: 12, maxCardLength: 19, formatPattern: "#### #### #### #### ###",
            securityCodeLength: 3, securityCodeName: SecurityCode.cvv.rawValue, imageName: "Unknown-Card")
        case .EMPTY: return Card(
            defaultName: "Empty", regex: "^$",
            minCardLength: 12, maxCardLength: 19, formatPattern: "#### #### #### #### ###",
            securityCodeLength: 3, securityCodeName: SecurityCode.cvv.rawValue, imageName: "Unknown-Card")
        }
    }
        static func forCardNumber(cardNumber: String) -> Card {
        let patternMatch = forCardPattern(cardNumber: cardNumber)
        if patternMatch.defaultName != "Empty" && patternMatch.defaultName != "Unknown" {
                return patternMatch
            } else {
                return CardType.EMPTY.instance
            }
        }


        private static func forCardPattern(cardNumber: String) -> Card {
            for card in CardType.allCases {
                if NSPredicate(format: "SELF MATCHES %@", card.instance.regex).evaluate(with: cardNumber) && cardNumber.count <= card.instance.maxCardLength {
                    return card.instance
                }
            }
            return CardType.EMPTY.instance
        }
}


internal enum SecurityCode: String {
    case cvv = "cvv"
    case cvc = "cvc"
    case cvn = "cvn"
    case cid = "cid"
}
