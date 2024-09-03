/*
 * Copyright (c) 2022 Skyflow
*/

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
    var cardLengths: [Int]
    var formatPattern: String
    var securityCodeLength: Int
    var securityCodeName: String
    var imageName: String
    public required init( defaultName: String, regex: String, cardLengths: [Int], formatPattern: String, securityCodeLength: Int, securityCodeName: String, imageName: String) {
        self.defaultName = defaultName
        self.regex = regex
        self.formatPattern = formatPattern
        self.cardLengths = cardLengths
        self.securityCodeLength = securityCodeLength
        self.securityCodeName = securityCodeName
        self.imageName = imageName
    }
    public init(defaultName: String, imageName: String) {
        self.defaultName = defaultName
        self.imageName = imageName
        self.regex = ""
        self.cardLengths = []
        self.formatPattern = ""
        self.securityCodeLength = 0
        self.securityCodeName = ""
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
    case CARTES_BANCAIRES
    case UNKNOWN
    case EMPTY

    var instance: Card {
        switch self {
        case .VISA : return Card(
            defaultName: "Visa", regex: "^4\\d*", cardLengths: [13, 16],
            formatPattern: "#### #### #### ####", securityCodeLength: 3,
            securityCodeName: SecurityCode.cvv.rawValue, imageName: "Visa-Card")

        case .MASTERCARD: return Card(
            defaultName: "Mastercard", regex: "^(5[1-5]|222[1-9]|22[3-9]|2[3-6]|27[0-1]|2720)\\d*",
            cardLengths: [16], formatPattern: "#### #### #### ####",
            securityCodeLength: 3, securityCodeName: SecurityCode.cvc.rawValue, imageName: "Mastercard-Card")

        case .DISCOVER : return Card(
            defaultName: "Discover", regex: "^(6011|65|64[4-9]|622)\\d*",
            cardLengths: [16, 17, 18, 19],
            formatPattern: "#### #### #### #### ###", securityCodeLength: 3, securityCodeName: SecurityCode.cid.rawValue, imageName: "Discover-Card")

        case .AMEX: return Card(
            defaultName: "Amex", regex: "^3[47]\\d*",
            cardLengths: [15], formatPattern: "#### ###### #####",
            securityCodeLength: 4, securityCodeName: SecurityCode.cid.rawValue, imageName: "Amex-Card")

        case .DINERS_CLUB: return Card(
            defaultName: "DinersClub", regex: "^(36|38|30[0-5])\\d*",
            cardLengths: [14,15,16, 17, 18, 19],
            formatPattern: "#### ###### #########", securityCodeLength: 3,
            securityCodeName: SecurityCode.cvv.rawValue, imageName: "Diners-Card")

        case .JCB: return Card(
            defaultName: "Jcb", regex: "^35\\d*",
            cardLengths: [16, 17, 18, 19],
            formatPattern: "#### #### #### #### ###", securityCodeLength: 3,
            securityCodeName: SecurityCode.cvv.rawValue, imageName: "JCB-Card")

        case .MAESTRO: return Card(
            defaultName: "Maestro", regex: "^(5018|5020|5038|5043|5[6-9]|6020|6304|6703|6759|676[1-3])\\d*",
            cardLengths: [12, 13, 14, 15, 16, 17, 18, 19],
            formatPattern: "#### #### #### #### ###", securityCodeLength: 3,
            securityCodeName: SecurityCode.cvc.rawValue, imageName: "Maestro-Card")

        case .UNIONPAY: return Card(
            defaultName: "Unionpay", regex: "^62\\d*",
            cardLengths: [16, 17, 18, 19], formatPattern: "#### #### #### #### ###", securityCodeLength: 3,
            securityCodeName: SecurityCode.cvn.rawValue, imageName: "Unionpay-Card")

        case .HIPERCARD: return Card(
            defaultName: "Hipercard", regex: "^606282\\d*",
            cardLengths: [14, 15, 16, 17, 18, 19], formatPattern: "#### #### #### #### ###",
            securityCodeLength: 3, securityCodeName: SecurityCode.cvc.rawValue, imageName: "Hipercard-Card")
        case .UNKNOWN: return Card(
            defaultName: "Unknown", regex: "\\d+",
            cardLengths: [12, 13, 14, 15, 16, 17, 18, 19], formatPattern: "#### #### #### #### ###",
            securityCodeLength: 3, securityCodeName: SecurityCode.cvv.rawValue, imageName: "Unknown-Card")
        case .EMPTY: return Card(
            defaultName: "Empty", regex: "^$",
            cardLengths: [12, 13, 14, 15, 16, 17, 18, 19], formatPattern: "#### #### #### #### ###",
            securityCodeLength: 3, securityCodeName: SecurityCode.cvv.rawValue, imageName: "Unknown-Card")
        case .CARTES_BANCAIRES:
            return Card(defaultName: "Cartes Bancaires", imageName: "Cartes-Bancaires-Card")
        }
    }
        static func forCardNumber(cardNumber: String) -> CardType {
        let patternMatch = forCardPattern(cardNumber: cardNumber)
            if patternMatch.instance.defaultName != "Empty" {
                return patternMatch
            } else {
                return CardType.EMPTY
            }
        }


        private static func forCardPattern(cardNumber: String) -> CardType {
            for card in CardType.allCases {
                if NSPredicate(format: "SELF MATCHES %@", card.instance.regex).evaluate(with: cardNumber){
                    return card
                }
            }
            return CardType.EMPTY
        }
}


internal enum SecurityCode: String {
    case cvv = "cvv"
    case cvc = "cvc"
    case cvn = "cvn"
    case cid = "cid"
}

public enum CardIconAlignment {
  case left
  case right
}
