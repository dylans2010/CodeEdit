import ArgumentParser

struct {{PROJECT_NAME}}: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A powerful command-line tool built with Swift.",
        version: "1.0.0"
    )

    @Option(name: .shortAndLong, help: "Name to greet.")
    var name: String = "World"

    @Flag(name: .shortAndLong, help: "Print extra debug details.")
    var verbose: Bool = false

    mutating func run() throws {
        if verbose {
            print("[debug] Starting {{PROJECT_NAME}} execution...")
        }
        print("Hello, \(name)!")
    }
}

{{PROJECT_NAME}}.main()
