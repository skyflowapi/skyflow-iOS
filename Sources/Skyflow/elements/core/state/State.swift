/*
 * Copyright (c) 2022 Skyflow
 */

import Foundation
#if os(iOS)
import UIKit
#endif

internal class State {
    internal(set) open var columnName: String!
    internal(set) open var isRequired = false
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
