import XCTest
@testable import Swift_HTTP

final class Swift_HTTPTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Swift_HTTP().text, "Hello, World!")
    }
}
