import XCTest
@testable import {{PROJECT_NAME}}

final class {{PROJECT_NAME}}Tests: XCTestCase {
    func testGreet() {
        let pkg = {{PROJECT_NAME}}()
        XCTAssertEqual(pkg.greet("Antigravity"), "Hello, Antigravity from {{PROJECT_NAME}}!")
    }
}
