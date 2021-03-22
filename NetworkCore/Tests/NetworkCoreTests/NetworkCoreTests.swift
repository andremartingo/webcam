import XCTest
@testable import NetworkCore

final class NetworkCoreTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(NetworkCore().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
