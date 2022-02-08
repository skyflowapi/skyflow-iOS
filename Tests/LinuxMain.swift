import XCTest

var tests = [XCTestCaseEntry]()
tests += skyflow_iOS_collectTests.allTests()
tests += skyflow_iOS_connectionTests.allTests()
tests += skyflow_iOS_revealTests.allTests()
test += skyflow_iOS_errorTests.allTests()
test += skyflow_iOS_getByIdTests.allTests()
test += skyflow_iOS_elementTests.allTests()
test += skyflow_iOS_utilTests.allTests()
XCTMain(tests)
