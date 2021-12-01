import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(skyflow_iOS_elementTests.allTests),
        testCase(InputFormattingTests.allTests)
    ]
}
#endif
