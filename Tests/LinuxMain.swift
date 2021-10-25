import XCTest

import skyflow_iOS_collectTests
import Gateway_tests

var tests = [XCTestCaseEntry]()
tests += skyflow_iOS_collectTests.allTests()
tests += skyflow_iOS_gatewayTests.allTests()
tests += skyflow_iOS_revealTests.allTests()
test += skyflow_iOS_errorTests.allTests()
test += skyflow_iOS_getByIdTests.allTests()
test += skyflow_iOS_elementTests.allTests()
XCTMain(tests)
