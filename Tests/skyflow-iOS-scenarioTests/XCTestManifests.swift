/*
 * Copyright (c) 2022 Skyflow
*/

import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(scenaioTests.allTests)
    ]
}
#endif
