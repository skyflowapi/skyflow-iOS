import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(skyflow_iOS_collectTests.allTests)
    ]
}
#endif
