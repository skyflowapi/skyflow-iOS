/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation

/**
 Validate input in scope of Card Expiration Month/Year, e.x.: [01/22, 12/29].
 */

internal enum SkyflowCardExpirationDateFormat {
    /// Exp.Date in format mm/yy: 01/22
    case shortYear

    /// Exp.Date in format mm/yyyy: 01/2022
    case longYear

    var yearCharacters: Int {
        switch self {
        case .shortYear:
            return 2
        case .longYear:
            return 4
        }
    }

    var monthCharacters: Int {
        return 2
    }

    internal var dateYearFormat: String {
        switch self {
        case .shortYear:
            return "yy"
        case .longYear:
            return "yyyy"
        }
    }
}

internal struct SkyflowValidateCardExpirationDate: ValidationRule {
    /// Validation Error
    public let error: SkyflowValidationError
    public let format: String

    /// Initialzation
    public init(format: String, error: SkyflowValidationError) {
        self.error = error
        self.format = format
    }
}

extension SkyflowValidateCardExpirationDate: SkyflowInternalValidationProtocol {
    /// Validation function for expire date.
    public func validate(_ text: String?) -> Bool {
        
        guard let text = text else {
            return false
        }
        
        if text.isEmpty {
            return true
        }
        
        if text.count != format.count {
            return false
        }

        var dateFormat: SkyflowCardExpirationDateFormat

        if text.count == 7 {
            dateFormat = SkyflowCardExpirationDateFormat.longYear
        } else if text.count == 5 {
            dateFormat = SkyflowCardExpirationDateFormat.shortYear
        } else {
            return false
        }

        let monthChars = dateFormat.monthCharacters
        let yearChars = dateFormat.yearCharacters
        guard text.count == (monthChars + yearChars + 1) else { return false }

        var month: String
        var year: String
        if format.starts(with: "mm") {
            month = String(text.prefix(monthChars))
            year = String(text.suffix(yearChars))
        } else {
            month = String(text.suffix(monthChars))
            year = String(text.prefix(yearChars))
        }

        let presentYear = Calendar(identifier: .gregorian).component(.year, from: Date())
        let presentMonth = Calendar(identifier: .gregorian).component(.month, from: Date())

        guard let inputMonth = Int(month), (1...12).contains(inputMonth), var inputYear = Int(year) else {
            return false
        }
        /// convert text year to long format if needed
        inputYear = yearChars == 2 ? (inputYear + 2000) : inputYear
        if inputYear < presentYear || inputYear > (presentYear + 50) {
            return false
        }

        if inputYear == presentYear && inputMonth < presentMonth {
            return false
        }
        return true
    }
}
