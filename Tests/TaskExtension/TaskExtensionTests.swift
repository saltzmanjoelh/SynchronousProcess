import XCTest
@testable import TaskExtension

class TaskExtensionTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(TaskExtension().text, "Hello, World!")
    }


    static var allTests : [(String, (TaskExtensionTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
