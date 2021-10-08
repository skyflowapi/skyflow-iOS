import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(skyflow_iOS_collectTests.allTests),
        testCase(Skyflow_iOS_collectErrorTests.allTests)
    ]
}
#endif
