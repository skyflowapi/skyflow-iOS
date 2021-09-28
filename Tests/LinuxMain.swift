import XCTest

import skyflow_iOS_collectTests
import Gateway_tests

var tests = [XCTestCaseEntry]()
tests += skyflow_iOS_collectTests.allTests()
tests += skyflow_iOS_gatewayTests.allTests()
XCTMain(tests)
