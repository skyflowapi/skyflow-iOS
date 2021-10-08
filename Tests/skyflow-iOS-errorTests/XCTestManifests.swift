import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(skyflow_iOS_collectErrorTests.allTests),
        testCase(Skyflow_iOS_revealErrorTests.allTests)
    ]
}
#endif
