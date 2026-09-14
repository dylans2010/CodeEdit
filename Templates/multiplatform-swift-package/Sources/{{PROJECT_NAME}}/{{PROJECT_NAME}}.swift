import Foundation

public struct {{PROJECT_NAME}} {
    public private(set) var version = "1.0.0"

    public init() {}

    public func greet(_ recipient: String) -> String {
        "Hello, \(recipient) from {{PROJECT_NAME}}!"
    }
}
