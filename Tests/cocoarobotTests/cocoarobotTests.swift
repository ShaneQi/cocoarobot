import XCTest
@testable import cocoarobot

class testTests: XCTestCase {
    func testExample() {
		XCTAssert("hello world" == "hello world")
    }


    static var allTests : [(String, (testTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
