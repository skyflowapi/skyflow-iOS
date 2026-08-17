/*
 * Copyright (c) 2022 Skyflow
*/

import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(skyflow_iOS_elementTests.allTests),
        testCase(InputFormattingTests.allTests),
        testCase(TextFieldDelegateTests.allTests),
        testCase(CollectElementOptionsTests.allTests)
    ]
}
#endif
