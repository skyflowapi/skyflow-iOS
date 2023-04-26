/*
 * Copyright (c) 2022 Skyflow
*/

import Foundation
#if os(iOS)
import UIKit
#endif


/// An object that describes `SkyflowTextField` state.
/// State attributes are read-only.
internal class State {
    /// `CollectElementOptions.columnName` associated  with `SkyflowTextField`
    internal(set) open var columnName: String!

    /// set as true if  `SkyflowTextField` input is required to fill
    internal(set) open var isRequired = false

    /// true if `SkyflowTextField` input in valid
    // internal(set) open var isValid: Bool = false

    init(columnName: String, isRequired: Bool) {
        self.columnName = columnName
        self.isRequired = isRequired
    }
    public var show: String {
        var result = ""
        guard let columnName = columnName else {
            return "Alias property is empty"
        }

        result = """
        "\(columnName)": {
            "isRequired": \(isRequired)
        }
        """
        return result
    }

    public func getState() -> [String: Any] {
        var result = [String: Any]()
            result["isRequired"] = isRequired
            result["columnName"] = columnName

        return result
    }
}
