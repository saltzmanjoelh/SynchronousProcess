import XCTest
@testable import SynchronousProcess

class SynchronousProcessTests: XCTestCase {
    func testMultipleBashCalls() {
        
        let result = Process.run("/bin/bash", arguments: ["-c", "echo test && echo test2; echo test3"], silenceOutput: false)
        
        if let error = result.error {
            XCTFail("\(error)")
        }
        XCTAssertNotNil(result.output)
        if let output = result.output {
            XCTAssertEqual(output, "test\ntest2\ntest3\n")
        }
    }


    static var allTests : [(String, (SynchronousProcessTests) -> () throws -> Void)] {
        return [
            ("testMultipleBashCalls", testMultipleBashCalls),
        ]
    }
}
