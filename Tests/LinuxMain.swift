/*
 * Copyright (c) 2022 Skyflow
*/

import XCTest

var tests = [XCTestCaseEntry]()
tests += skyflow_iOS_collectTests.allTests()
tests += skyflow_iOS_revealTests.allTests()
tests += skyflow_iOS_getByIdTests.allTests()
tests += skyflow_iOS_elementTests.allTests()
tests += skyflow_iOS_utilTests.allTests()
XCTMain(tests)
