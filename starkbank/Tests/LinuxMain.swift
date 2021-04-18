import XCTest

import starkbankTests

var tests = [XCTestCaseEntry]()
tests += starkbankTests.allTests()
XCTMain(tests)
