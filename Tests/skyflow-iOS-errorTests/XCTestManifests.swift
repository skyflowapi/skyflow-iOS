/*
 * Copyright (c) 2022 Skyflow
 */

import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(Skyflow_iOS_collectErrorTests.allTests),
        testCase(Skyflow_iOS_revealErrorTests.allTests)
    ]
}
#endif
