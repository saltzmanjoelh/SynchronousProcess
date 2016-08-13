import XCTest
@testable import SynchronousTask

class SynchronousTaskTests: XCTestCase {
    func testMultipleBashCalls() {
        
        let result = Task.run(launchPath: "/bin/bash", arguments: ["-c", "echo test && echo test2; echo test3"], silenceOutput: false)
        
        if let error = result.error {
            XCTFail("\(error)")
        }
        XCTAssertNotNil(result.output)
        if let output = result.output {
            XCTAssertEqual(output, "test\ntest2\ntest3\n")
        }
    }


    static var allTests : [(String, (SynchronousTaskTests) -> () throws -> Void)] {
        return [
            ("testMultipleBashCalls", testMultipleBashCalls),
        ]
    }
}
