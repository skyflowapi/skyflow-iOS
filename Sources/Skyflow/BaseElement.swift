/*
 * Copyright (c) 2022 Skyflow
 */

import Foundation

public protocol BaseElement {
    func setError(_ error: String)
    func resetError()
    func getID() -> String
}
