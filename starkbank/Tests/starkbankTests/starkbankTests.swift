import XCTest
@testable import starkbank

final class starkbankTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(starkbank().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
