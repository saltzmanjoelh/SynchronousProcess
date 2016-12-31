import XCTest
@testable import SynchronousProcess

class SynchronousProcessTests: XCTestCase {
    func testMultipleBashCalls() {
        
        let result = Process.run("/bin/bash", arguments: ["-c", "echo test && echo test2; echo test3"], printOutput: false)
        
        if let error = result.error {
            XCTFail("\(error)")
        }
        XCTAssertNotNil(result.output)
        if let output = result.output {
            XCTAssertEqual(output, "test\ntest2\ntest3\n")
        }
    }
    
    func testOutputPrefix() {
        let prefix = UUID().uuidString
        let result = Process.run("/bin/bash", arguments: ["-c", "echo testOutputPrefix"], printOutput: true, outputPrefix: prefix)
        
        if let error = result.error {
            XCTFail("\(error)")
        }
        XCTAssertNotNil(result.output)
        if let output = result.output {
            XCTAssertEqual(output, "\(prefix): testOutputPrefix\n")
        }
    }


    static var allTests : [(String, (SynchronousProcessTests) -> () throws -> Void)] {
        return [
            ("testMultipleBashCalls", testMultipleBashCalls),
        ]
    }
}
